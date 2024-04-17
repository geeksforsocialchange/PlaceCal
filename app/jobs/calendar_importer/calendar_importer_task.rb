# frozen_string_literal: true

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
    parsed_events = event_data_from_parser

    if parsed_events.present?
      # this can be useful if you want to force import on your local machine
      # if @force_import
      #   calendar.events.destroy_all
      # end

      parsed_events.each do |parsed_event|
        process_event parsed_event
      end

      purge_stale_events_from_calendar
    end

    calendar.flag_complete_import_job! notices, calendar_source.checksum, parser::KEY
  end

  private

  def notices
    @notices ||= []
  end

  def active_event_uids
    @active_event_uids ||= Set.new
  end

  def parser
    @parser ||= CalendarImporter::CalendarImporter.new(calendar).parser
  end

  def calendar_source
    @calendar_source ||= parser.new(
      calendar,
      from: from_date,
      force_import: force_import
    ).calendar_to_events
  end

  def event_data_from_parser
    return [] if !force_import && calendar.last_checksum == calendar_source.checksum

    calendar_source.events.map do |event_data|
      CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    end
  end

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
