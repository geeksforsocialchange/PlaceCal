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

  # the main importing function
  def run
    notices = []

    calendar_source = CalendarImporter::CalendarImporter.new(calendar,
                                                             from: from_date,
                                                             force_import: @force_import).parse
    return if !@force_import && calendar.last_checksum == calendar_source.checksum

    parsed_events = calendar_source.events.map do |event_data|
      CalendarImporter::EventResolver.new(event_data, calendar, notices, from_date)
    end
    return if parsed_events.blank?

    all_event_uids = Set.new(calendar.events.upcoming.pluck(:uid))
    active_event_uids = Set.new

    parsed_events.each do |parsed_event|
      # is source event valid?
      # now find all occurrences of event in calendar
      # set up location from strategy

      # find all events in calendar with same UID
      # if recurring event?
      #   delete upcoming calendar events that have the same start and end time as our parsed_event
      #
      # for each occurence
      #   skip if more than a day apart (?)
      #   setup start_time and end_time
      #   if this is recurring
      #     try to find an event with the same start time and end time
      #     or make a new event
      #   set are_spaces_available
      #   save event
      #
      # delete all upcoming events that have not been created/updated by this import

      next if parsed_event.is_private?
      next if parsed_event.has_no_occurences?

      parsed_event.determine_location_for_strategy
      # next if parsed_event.is_address_missing?

      active_event_uids << parsed_event.uid

      parsed_event.save_all_occurences
    end

    purge_stale_events_from_calendar all_event_uids - active_event_uids

    calendar.reload # reload the record from database to clear out any invalid events to avoid attempts to save them

    Calendar.record_timestamps = false
    calendar.update!(
                     notices: notices,
                     last_checksum: calendar_source.checksum,
                     last_import_at: DateTime.current,
                     critical_error: nil
                    )
  ensure
    Calendar.record_timestamps = true
  end

  def purge_stale_events_from_calendar(stale_event_uids)
    calendar.events.upcoming.where( uid: stale_event_uids).destroy_all
  end
end
