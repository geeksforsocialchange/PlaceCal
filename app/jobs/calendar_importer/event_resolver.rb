class CalendarImporter::EventResolver
  attr_reader :data
  attr_reader :uid
  attr_reader :notices

  def initialize(event_data, calendar, notices)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
  end

  def is_valid?
    return false if parsed_event.is_private?
    return false if parsed_event.occurrences.empty?
    true
  end

  def event
    @event ||= calendar.events.new # ???
  end
  
  def location_for_strategy
    case calendar.strategy
    when 'event'
      if data.has_location?
        if place.present?
          # place = 'attempt to match location'
          # address = 'calendar.place.address || location'

          place = Partner.find_like_name(data.location)
          address = place.address
          address ||= Address.search(data.location)

        else # no place, yes location
          #place = 'try to look up place from location'
          #address = 'place address or location'

          place = Partner.find_like_name(data.location)
          address = place.address
          address ||= Address.search(data.location)
        end
        
      else # no location
        if place.present?
          raise 'error: warning2: '

        else # no place, no location
          raise 'error: warning1: '
        end
      end

    when 'event_override'
      if data.has_location?
        if place.present?
          # place = 'attempt to match location'
          # address = 'calendar.place.address || location'
          place = Place.find_like_name(data.location)
          address = place.address
          address ||= Address.search(data.location)

        else # no place, yes location
          #place = 'attempt to match location'
          #address = 'place.address || location'
          place = Place.find_like_name(data.location)
          address = place.address
          address ||= Address.search(data.location)

          if address.nil?
            raise 'info1: could not match location or place, would you like to add it?'
          end
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          place = calendar.place
          address = place.address

        else # no place, no location
          raise 'error: warning1: could not determine where this event is.'
        end
      end

    when 'place' # location
      if data.has_location?
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          place = calendar.place.address
          address = place.address

        else # no place, yes location
          raise 'N/A'
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          place = calendar.place.address
          address = place.address

        else # no place, no location
          raise 'N/A'
        end
      end

    when 'room_number'
      if data.has_location?
        if place.present?
          #place = 'calendar.place'
          #address = '#{location}, place.address'
          place = calendar.place.address
          address = place.address.prepend_line(data.location)


        else # no place, yes location
          raise 'N/A'
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          place = calendar.place.address
          address = place.address

        else # no place, no location
          raise 'N/A'
        end
      end

    else
      raise "Calendar import strategy unknown! (#{calendar.strategy})"
    end

    event.place = place
    event.address = address
  end
  
  def create_or_update_events
    @important_notices = []
    calendar_events    = events.upcoming.where(uid: event_data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if event_data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurrences.map(&:start_time), occurrences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurrences.each do |occurrence|
      # Skip if more than a day apart
      next if occurrence.end_time && (occurrence.end_time.to_date - occurrence.start_time.to_date).to_i > 1
      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }

      event = event_data.recurring_event? ? calendar_events.find_by(event_time) : calendar_events.first if calendar_events.present?
      event = events.new if event.blank?

      event_time[:are_spaces_available] = occurrence.status if occurrence.respond_to?(:status)

      unless event.update event_data.attributes.merge(event_time)
        @important_notices << { event: event, errors: event.errors.full_messages }
      end
    end

    @important_notices
  end
  
  def try_to_find_location
    return if data.location.blank?
    
  end
  
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

__END__

      if data.has_location?
        if place.present?
          'look up location'
        else
          'look up location'
        end
        
      else
        if place.present?
          'no location is present'
        else
          error 'No location or place'
        end
      end

