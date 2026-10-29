# frozen_string_literal: true

class CalendarImporter::CalendarImporterTask
  MAX_OCCURENCES = 20_000

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
        break unless within_occurence_limit?(parsed_event)

        process_event parsed_event
      end

      # Events past the limit were never processed, so their rows would look stale
      purge_stale_events_from_calendar unless @occurence_limit_reached
    end

    calendar.flag_complete_import_job! notices, parser::KEY
    calendar.flag_checksum_change!(calendar_source.checksum) if calendar_source.checksum_changed
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

  # Get a properly formatted event list from the source
  def calendar_source
    @calendar_source ||= parser.new(
      calendar,
      from: from_date,
      force_import:
    ).calendar_to_events
  end

  # Send the event data to be imported
  def event_data_from_parser
    return [] if !force_import && !calendar_source.checksum_changed

    notices.concat(calendar_source.notices)
    calendar_source.events.map do |event_data|
      CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    end
  end

  # Attempt to create each event
  def process_event(parsed_event)
    return if parsed_event.private?
    return if parsed_event.no_occurences?

    parsed_event.determine_online_location

    parsed_event.determine_location_for_strategy

    active_event_uids << parsed_event.uid

    parsed_event.save_all_occurences
  rescue CalendarImporter::LocationResolver::Problem => e
    notices << e.message
  end

  def within_occurence_limit?(parsed_event)
    return true if parsed_event.private?

    @occurence_count = @occurence_count.to_i + parsed_event.occurences.size
    return true if @occurence_count <= MAX_OCCURENCES

    notices << I18n.t('admin.calendars.importer.calendar_occurrence_limit', count: MAX_OCCURENCES)
    @occurence_limit_reached = true
    false
  end

  def purge_stale_events_from_calendar
    all_event_uids = Set.new(calendar.events.upcoming.pluck(:uid))
    stale_event_uids = all_event_uids - active_event_uids

    calendar.events.upcoming.where(uid: stale_event_uids).destroy_all
  end
end
