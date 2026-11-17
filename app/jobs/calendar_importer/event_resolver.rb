# frozen_string_literal: true

# Coordinates event import: resolves the online link, location and organiser, and saves occurrences.
class CalendarImporter::EventResolver
  # Twice-daily for a year fits; a minutely or hourly rule does not
  MAX_OCCURRENCES_PER_EVENT = 1000

  attr_reader :data, :uid, :report, :calendar, :unreadable_address_reason, :resolved_attributes, :location_match

  delegate :private?, to: :data

  # @param report [CalendarImporter::ImportReport] the import run's report, which this event's notices are added to
  def initialize(event_data, calendar, report, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @report = report
    @from_date = from_date
  end

  def no_occurrences?
    occurrences.none?
  end

  def occurrences
    @occurrences ||= begin
      all = data.occurrences_between(@from_date, Calendar.import_up_to)
      if all.size > MAX_OCCURRENCES_PER_EVENT
        report.add(:occurrence_limit, 'admin.calendars.importer.occurrence_limit',
                   values: { summary: data.summary, count: MAX_OCCURRENCES_PER_EVENT }, uid:, title: data.summary)
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
    @location_match = location.match

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

    result.failures.each do |failure|
      report.add_messages(:failed_save, failure.errors.full_messages, uid:, title: data.summary)
    end
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
