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

  # @return [CalendarImporter::OccurrenceSync::Result]
  def save_all_occurrences
    result = CalendarImporter::OccurrenceSync.new(
      calendar:,
      uid:,
      from_date: @from_date,
      occurrences:,
      series: series?,
      attributes_for: ->(occurrence) { data.attributes_for(occurrence).merge(resolved_attributes) }
    ).call

    result.failures.each { |failure| notices << failure.errors.full_messages.join(', ') }
    result
  end

  private

  def organiser_id
    calendar.organiser_id
  end

  # RDATE gives an event several dates without an RRULE
  def series?
    data.recurring_event? || occurrences.many?
  end
end
