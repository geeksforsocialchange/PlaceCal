# frozen_string_literal: true

# Coordinates event import: resolves the online link, location and organiser, and saves occurrences.
class CalendarImporter::EventResolver
  # Twice-daily for a year fits; a minutely or hourly rule does not
  MAX_OCCURRENCES_PER_EVENT = 1000

  attr_reader :data, :uid, :notices, :calendar, :unreadable_address_reason, :resolved_attributes

  delegate :private?, to: :data

  def initialize(event_data, calendar, notices, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
    @from_date = from_date
  end

  def no_occurrences?
    occurrences.none?
  end

  def occurrences
    @occurrences ||= begin
      all = data.occurrences_between(@from_date, Calendar.import_up_to)
      if all.size > MAX_OCCURRENCES_PER_EVENT
        notices << I18n.t('admin.calendars.importer.occurrence_limit', summary: data.summary, count: MAX_OCCURRENCES_PER_EVENT)
        all = all.sort_by(&:start_time).first(MAX_OCCURRENCES_PER_EVENT)
      end
      all
    end
  end

  # The online address is found or created first, so it is kept even when the location raises a Problem.
  # @return [Hash] the place_id, address_id, organiser_id and online_address_id for each saved row
  # @raise [CalendarImporter::LocationResolver::Problem] when the calendar's settings can't place the event
  def resolve
    online_address_id = data.online_event_id

    location_resolver = CalendarImporter::LocationResolver.new(calendar, data)
    location = location_resolver.resolve
    @unreadable_address_reason = location_resolver.unreadable_address_reason

    @resolved_attributes = {
      place_id: location.place&.id,
      address_id: location.address&.id,
      organiser_id:,
      online_address_id:
    }
  end

  def save_all_occurrences
    calendar_events = calendar.events.where(uid: data.uid)
    remove_stale_occurrences(calendar_events)

    occurrences.each do |occurrence|
      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }
      event = series? ? calendar_events.find_by(event_time) : one_off_event(calendar_events)

      # Clean up any remaining duplicates for this specific occurrence
      calendar_events.where(event_time).where.not(id: event.id).delete_all if event&.persisted?

      # Not built through calendar.events, where an invalid event would fail the calendar's own save
      event ||= Event.new(calendar_id: calendar.id)

      event_time[:are_spaces_available] = occurrence.status if occurrence.respond_to?(:status)

      attributes = data.attributes_for(occurrence).merge(resolved_attributes).merge(event_time)
      begin
        notices << event.errors.full_messages.join(', ') unless event.update(attributes)
      rescue ActiveRecord::RecordNotUnique
        # Duplicate detected by DB constraint: find and update existing instead
        existing = calendar.events.find_by!(uid: data.uid, dtstart: event_time[:dtstart], dtend: event_time[:dtend])
        notices << existing.errors.full_messages.join(', ') unless existing.update(attributes)
      end
    end
  end

  private

  def organiser_id
    calendar.organiser_id
  end

  # RDATE gives an event several dates without an RRULE
  def series?
    data.recurring_event? || occurrences.many?
  end

  # Past rows are history, and occurrences are only generated from the import's from_date
  def remove_stale_occurrences(calendar_events)
    upcoming = calendar_events.where(dtstart: @from_date..)
    stale = if series?
              upcoming.without_matching_times(occurrences.map { |o| [o.start_time, o.end_time] })
            else
              upcoming.where.not(id: one_off_event(calendar_events))
            end
    stale.destroy_all
  end

  # Reuses an existing row so a rescheduled one-off keeps its id
  def one_off_event(calendar_events)
    occurrence = occurrences.first
    @one_off_event ||= calendar_events.find_by(dtstart: occurrence.start_time, dtend: occurrence.end_time) ||
                       calendar_events.where(dtstart: @from_date..).order(:dtstart).first ||
                       calendar_events.order(:dtstart).first
  end
end
