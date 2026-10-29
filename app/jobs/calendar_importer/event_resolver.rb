# frozen_string_literal: true

# Coordinates event import: resolves location, detects online links, and saves occurrences.
#
# Delegates location resolution to LocationResolver and online detection to OnlineDetector.
class CalendarImporter::EventResolver
  # Twice-daily for a year fits; a minutely or hourly rule does not
  MAX_OCCURENCES = 1000

  attr_reader :data, :uid, :notices, :calendar

  delegate :private?, to: :data

  def initialize(event_data, calendar, notices, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
    @from_date = from_date
  end

  def no_occurences?
    occurences.none?
  end

  def occurences
    @occurences ||= begin
      all = data.occurrences_between(@from_date, Calendar.import_up_to)
      if all.size > MAX_OCCURENCES
        notices << I18n.t('admin.calendars.importer.occurrence_limit', summary: data.summary, count: MAX_OCCURENCES)
        all = all.sort_by(&:start_time).first(MAX_OCCURENCES)
      end
      all
    end
  end

  def determine_online_location
    CalendarImporter::OnlineDetector.new(data).detect
  end

  def determine_location_for_strategy
    place, address = CalendarImporter::LocationResolver.new(calendar, data).resolve

    data.place_id = place.id if place
    data.address_id = address&.id
    data.organiser_id = calendar.organiser_id
  end

  def save_all_occurences
    calendar_events = calendar.events.where(uid: data.uid)
    remove_stale_occurences(calendar_events)

    occurences.each do |occurence|
      event_time = { dtstart: occurence.start_time, dtend: occurence.end_time }
      event = data.recurring_event? ? calendar_events.find_by(event_time) : one_off_event(calendar_events)

      # Clean up any remaining duplicates for this specific occurrence
      calendar_events.where(event_time).where.not(id: event.id).delete_all if event&.persisted?

      # Not built through calendar.events, where an invalid event would fail the calendar's own save
      event ||= Event.new(calendar_id: calendar.id)

      event_time[:are_spaces_available] = occurence.status if occurence.respond_to?(:status)

      attributes = data.attributes_for(occurence).merge(event_time)
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

  # Past rows are history, and occurrences are only generated from the import's from_date
  def remove_stale_occurences(calendar_events)
    upcoming = calendar_events.where(dtstart: @from_date..)
    stale = if data.recurring_event?
              upcoming.without_matching_times(occurences.map { |o| [o.start_time, o.end_time] })
            else
              upcoming.where.not(id: one_off_event(calendar_events))
            end
    stale.destroy_all
  end

  # Reuses an existing row so a rescheduled one-off keeps its id
  def one_off_event(calendar_events)
    occurence = occurences.first
    @one_off_event ||= calendar_events.find_by(dtstart: occurence.start_time, dtend: occurence.end_time) ||
                       calendar_events.where(dtstart: @from_date..).order(:dtstart).first ||
                       calendar_events.order(:dtstart).first
  end
end
