# frozen_string_literal: true

# Adapter between PlaceCal and PanCal: builds a PanCal::Source from the
# Calendar, reads the feed, persists the checksum, and feeds the canonical
# events through EventResolver.
class CalendarImporter::CalendarImporterTask
  attr_reader :calendar,
              :from_date,
              :force_import

  def initialize(calendar, from_date, force_import)
    @calendar = calendar
    @from_date = from_date
    @force_import = force_import
  end

  def run
    result = PanCal.read(calendar.pancal_source, force: force_import, logger: Rails.logger)

    # PanCal never mutates caller state — persisting the checksum is our job
    calendar.flag_checksum_change!(result.checksum) if result.changed?

    parsed_events = result.events.map do |event_data|
      CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    end

    if parsed_events.present?
      parsed_events.each do |parsed_event|
        process_event parsed_event
      end

      purge_stale_events_from_calendar
    end

    calendar.flag_complete_import_job! notices, result.reader_key
  end

  private

  def notices
    @notices ||= []
  end

  def active_event_uids
    @active_event_uids ||= Set.new
  end

  # Attempt to create each event
  def process_event(parsed_event)
    return if parsed_event.is_private?
    return if parsed_event.has_no_occurences?

    parsed_event.determine_online_location

    parsed_event.determine_location_for_strategy

    active_event_uids << parsed_event.uid

    parsed_event.save_all_occurences
  rescue CalendarImporter::EventResolver::Problem => e
    notices << e.message
  end

  def purge_stale_events_from_calendar
    all_event_uids = Set.new(calendar.events.upcoming.pluck(:uid))
    stale_event_uids = all_event_uids - active_event_uids

    calendar.events.upcoming.where(uid: stale_event_uids).destroy_all
  end
end
