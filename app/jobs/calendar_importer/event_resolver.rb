class CalendarImporter::EventResolver
  attr_reader :data
  attr_reader :uid
  attr_reader :notices

  def initialize(event_data, calendar, notices, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
    @from_date = from_date
  end

  def is_private?
    data.is_private?
  end

  def has_occurences?
    occurrence.count > 0
  end

  def occurences
    @occurences ||= data.occurrences_between(@from_date, Calendar.import_up_to)
  end

  def location_for_strategy
    case calendar.strategy
    when 'event'
      if data.has_location?
        if place.present?
          # place = 'attempt to match location'
          # address = 'calendar.place.address || location'

          place = Partner.fuzzy_find_by_location(event_location_components)
          address = place.address
          address ||= Address.search(data.location, event_location_components, data.postcode)

        else # no place, yes location
          #place = 'try to look up place from location'
          #address = 'place address or location'

          place = Partner.fuzzy_find_by_location(event_location_components)
          address = place.address
          address ||= Address.search(data.location, event_location_components, data.postcode)
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
          place = Place.fuzzy_find_by_location(event_location_components)
          address = place.address
          address ||= Address.search(data.location, event_location_components, data.postcode)

        else # no place, yes location
          #place = 'attempt to match location'
          #address = 'place.address || location'
          place = Place.fuzzy_find_by_location(event_location_components)
          address = place.address
          address ||= Address.search(data.location, event_location_components, data.postcode)

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
          new_address = place.address.dup
          address = new_address.prepend_room_number(data.location)


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

    data.place_id = place.id
    data.address_id = address.id
  end
  
  def save_all_occurences
    calendar_events = calendar.events.upcoming.where(uid: data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurrences.map(&:start_time), occurrences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurrences.each do |occurrence|
      # Skip if occurence is longer than 1 day
      next if occurrence.end_time && (occurrence.end_time.to_date - occurrence.start_time.to_date).to_i > 1

      event_time = { dtstart: occurrence.start_time, dtend: occurrence.end_time }
      event = nil

      if calendar_events.present?
        if data.recurring_event?
          event = calendar_events.find_by(event_time)
        else 
          event = calendar_events.first
        end
      end

      event ||= calendar.events.new

      event_time[:are_spaces_available] = occurrence.status if occurrence.respond_to?(:status)

      unless event.update data.attributes.merge(event_time)
        notices << { event: event, errors: event.errors.full_messages }
      end
    end
  end

  def event_location_components
    return @event_location_components if @event_location_components

    regex_string = 'UK|United Kingdom'
    regex_string += "|#{data.postcode.strip}" if data.postcode.present?

    regexp = Regexp.new(regex_string, Regexp::IGNORECASE)

    @event_location_components = data.location
      .split(', ')
      .map { |component| component.gsub(regexp, '').strip }
      .reject(&:blank?)
  end
end

