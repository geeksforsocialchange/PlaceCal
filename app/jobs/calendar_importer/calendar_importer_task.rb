
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

    parser = CalendarPuller.new(calendar, from: from)
    parsed_events = parser.parse.map { |event| EventResolver.new(event_data, calendar, notices) }
    return if parsed_events.events.blank?

    #event_uids = []

    parsed_events.events.each do |parsed_event|
      next unless parsed_event.is_valid?
      
      # event_uids << parsed_event.uid

      parsed_event.determine_location_for_strategy
      parsed_event.save
    end

    #handle_deleted_events(from, events_uids) unless events_uids.empty?

    reload # reload the record from database to clear out any invalid events to avoid attempts to save them

    begin
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
  end

  # Output constant for event import date limit
  def self.import_up_to
    1.year.from_now
  end
  
  def critical_import_failure(error, save_now=true)
    self.critical_error = error
    self.is_working = false
    self.save if save_now
  end




  # Destroys all events in the future if their UID is not included in the input `uids` list
  #
  # == Parameters
  # from::
  #   Unused.
  #
  # uids::
  #   A list of UID strings
  def handle_deleted_events(from, uids)
    upcoming_events = events.upcoming
    deleted_events = upcoming_events.where.not(uid: uids).pluck(:uid)

    return if deleted_events.blank?

    upcoming_events.where(uid: deleted_events).destroy_all
  end
  
  # Create Events using this Calendar
  # @param from [DateTime]
  def import_events(from)
    # done return unless place.present? # a quick fix to stop broken code from running

    # done. @notices = []
    # done. @events_uids = []

    # done parsed_events = events_from_source(from)

    # done. return if parsed_events.events.blank?

    parsed_events.events.each do |event_data|
      # done occurrences = event_data.occurrences_between(from, Calendar.import_up_to)
      # done next if event_data.private? || occurrences.blank?

      # done. @events_uids << event_data.uid
      # done. event_data.partner_id = partner_id

      #if %w[place room_number].include?(strategy)
      #  event_data.place_id = place_id

      #else
      #  id_type, id = get_place_or_address(event_data)
      #  event_data.place_id = id if id_type == :place_id
      #  event_data.address_id = id if id_type == :address_id
      #end

      # Create/Update the new event and update the Calendar import error log (notices) with any errors
      # done. @notices += create_or_update_events(event_data, occurrences, from)
    end

    #handle_deleted_events(from, @events_uids) if @events_uids

    #reload # reload the record from database to clear out any invalid events to avoid attempts to save them
    #begin
#      Calendar.record_timestamps = false
#      update!( 
#        notices: @notices, 
#        last_checksum: parsed_events.checksum,
#        last_import_at: DateTime.current,
#        critical_error: nil
#      )
#
#    ensure
#      Calendar.record_timestamps = true
#
#    end
  end
  
#  def create_or_update_events(event_data, occurrences, from)
#    @important_notices = []
#    calendar_events    = events.upcoming.where(uid: event_data.uid)
#
#    # If any dates of this event don't match the imported start times or end times, delete them
#    if event_data.recurring_event?
#      events_with_invalid_dates = calendar_events.without_matching_times(occurrences.map(&:start_time), occurrences.map(&:end_time))
#      events_with_invalid_dates.destroy_all
#    end
#
#    occurrences.each do |occurrence|
#      # Skip if more than a day apart
#      next if occurrence.end_time && (occurrence.end_time.to_date - occurrence.start_time.to_date).to_i > 1
#      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }
#
#      event = event_data.recurring_event? ? calendar_events.find_by(event_time) : calendar_events.first if calendar_events.present?
#      event = events.new if event.blank?
#
#      event_time[:are_spaces_available] = occurrence.status if occurrence.respond_to?(:status)
#
#      unless event.update event_data.attributes.merge(event_time)
#        @important_notices << { event: event, errors: event.errors.full_messages }
#      end
#    end
#
#    @important_notices
#  end

  def source_supported
    CalendarParser.new(self).validate_feed
    self.is_working = true
    self.critical_error = nil

  rescue CalendarParser::InaccessibleFeed, CalendarParser::UnsupportedFeed => e
    critical_import_failure(e, false)
  end

  # Import events from given URL
#  def events_from_source(from)
#  end

#  def get_place_or_address(event_data)
#    location = event_data.location
#
#    return (strategy.event_override? ? { place_id: place_id } : {}) if location.blank?
#
#    postcode   = event_data.postcode
#    regexp     = postcode.present? ? Regexp.new("#{postcode.strip}|UK|United Kingdom") : Regexp.new('UK|United Kingdom')
#    components = location.split(', ').map { |component| component.gsub(regexp, '').strip }.reject(&:blank?)
#
#    if place = Partner.find_by('lower(name) IN (?)', components.map(&:downcase))
#      return [ :place_id, place.id ]
#    else
#      return Address.search(location, components, postcode)
#    end
#  end

end
