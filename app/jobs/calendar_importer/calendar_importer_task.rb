
class CalendarImporter::CalendarImporterTask
  attr_reader :calendar
  attr_reader :from_date

  def initialize(calendar, from_date)
    @calendar = calendar
    @from_date = from_date
  end
  
  # the main importing function
  def run
    notices = []

    calendar_source = CalendarImporter.new(calendar, from: from).parse

    parsed_events = calendar_source.events.map { |event_data| EventResolver.new(event_data, calendar, notices) }
    return if parsed_events.blank?

    all_event_uids = Set.new(calendar.events.upcoming.pluck(:uid)
    active_event_uids = Set.new
    
    #event_uids = []

    parsed_events.events.each do |parsed_event|

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

      next unless parsed_event.is_valid?

      # occurrences = event_data.occurrences_between(from, Calendar.import_up_to)
      
      # event_uids << parsed_event.uid

      parsed_event.determine_location_for_strategy
      parsed_event.save
    end

    purge_stale_events_from_calendar all_event_uids - active_event_uids

    #handle_deleted_events(from, events_uids) unless events_uids.empty?

    reload # reload the record from database to clear out any invalid events to avoid attempts to save them

    Calendar.record_timestamps = false
    calendar.update!( 
                     notices: notices, 
                     last_checksum: parsed_events.checksum,
                     last_import_at: DateTime.current,
                     critical_error: nil
                    )

  ensure
    Calendar.record_timestamps = true
  end

  def purge_stale_events_from_calendar(stale_event_uids)
    calendar.events.upcoming.where( uid: stale_event_uids).destroy_all
  end

  # Destroys all events in the future if their UID is not included in the input `uids` list
  #
  # == Parameters
  # from::
  #   Unused.
  #
  # uids::
  #   A list of UID strings
#  def handle_deleted_events(from, uids)
#    upcoming_events = calendar.events.upcoming
#    deleted_events = upcoming_events.where.not(uid: uids).pluck(:uid)

#    return if deleted_events.blank?

#    upcoming_events.where(uid: deleted_events).destroy_all
#  end
  
  # Create Events using this Calendar
  # @param from [DateTime]
#  def import_events(from)
#    # done return unless place.present? # a quick fix to stop broken code from running
#
#    # done. @notices = []
#    # done. @events_uids = []
#
#    # done parsed_events = events_from_source(from)
#
#    # done. return if parsed_events.events.blank?
#
#    parsed_events.events.each do |event_data|
#      # done occurrences = event_data.occurrences_between(from, Calendar.import_up_to)
#      # done next if event_data.private? || occurrences.blank?
#
#      # done. @events_uids << event_data.uid
#      # done. event_data.partner_id = partner_id
#
#      #if %w[place room_number].include?(strategy)
#      #  event_data.place_id = place_id
#
#      #else
#      #  id_type, id = get_place_or_address(event_data)
#      #  event_data.place_id = id if id_type == :place_id
#      #  event_data.address_id = id if id_type == :address_id
#      #end
#
#      # Create/Update the new event and update the Calendar import error log (notices) with any errors
#      # done. @notices += create_or_update_events(event_data, occurrences, from)
#    end
#
#    #handle_deleted_events(from, @events_uids) if @events_uids
#
#    #reload # reload the record from database to clear out any invalid events to avoid attempts to save them
#    #begin
##      Calendar.record_timestamps = false
##      update!( 
##        notices: @notices, 
##        last_checksum: parsed_events.checksum,
##        last_import_at: DateTime.current,
##        critical_error: nil
##      )
##
##    ensure
##      Calendar.record_timestamps = true
##
##    end
#  end
  
end
