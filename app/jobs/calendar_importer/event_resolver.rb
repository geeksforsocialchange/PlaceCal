class CalendarImporter::EventResolver
  attr_reader :data
  attr_reader :uid
  attr_reader :notices
  attr_reader :calendar

  class Problem < StandardError
  end

  def initialize(event_data, calendar, notices, from_date)
    @data = event_data
    @uid = data.uid
    @calendar = calendar
    @notices = notices
    @from_date = from_date
  end

  def is_private?
    data.private?
  end

  def has_no_occurences?
    occurences.count == 0
  end

  def is_address_missing?
    data.address_id.nil?
  end

  def occurences
    @occurences ||= data.occurrences_between(@from_date, Calendar.import_up_to)
  end

  def determine_location_for_strategy
    place = calendar.place

    # this algorithm is derived from the notion doc at 
    #   GFSC
    #     PlaceCal
    #       PlaceCal Handbook
    #         PlaceCal developer handbook
    #           How does the Calendar importer detect Places and Addresses?

    case calendar.strategy
    when 'event'
      if data.has_location?

        # place = 'attempt to match location'
        # address = 'calendar.place.address || location'

        # try to find the place 
        place = Partner.fuzzy_find_by_location(event_location_components)

        # try to use that address
        address = place&.address

        # if no place, try to find an address
        address ||= Address.search(data.location, event_location_components, data.postcode)

        # if we have an address, try to use the place that address points to
        place ||= address&.partners.first

      else # no location
        if place.present?
          raise Problem.new('error: warning2: ')

        else # no place, no location
          raise Problem.new('error: warning1: ')
        end
      end

    when 'event_override'
      if data.has_location?
        # place = 'attempt to match location'
        # address = 'calendar.place.address || location'
        place = Partner.fuzzy_find_by_location(event_location_components)
        address = place&.address
        address ||= Address.search(data.location, event_location_components, data.postcode)

        if not place.present? # no place, yes location
          if address.nil?
            raise Problem.new('info1: could not match location or place, would you like to add it?')
          end
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          place = calendar.place
          address = place.address

        else # no place, no location
          raise Problem.new('error: warning1: could not determine where this event is.')
        end
      end

    when 'place' # location
      if data.has_location?
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          # xx place = calendar.place.address
          address = place.address

        else # no place, yes location
          raise Problem.new('N/A')
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          # xx place = calendar.place.address
          address = place.address

        else # no place, no location
          raise Problem.new('N/A')
        end
      end

    when 'room_number'
      if data.has_location?
        if place.present?
          #place = 'calendar.place'
          #address = '#{location}, place.address'
          
          # xx place = calendar.place.address
          new_address = place.address.dup
          address = new_address.prepend_room_number(data.location)
          address.save

        else # no place, yes location
          raise Problem.new('N/A')
        end
        
      else # no location
        if place.present?
          #place = 'calendar.place'
          #address = 'calendar.place.address'
          # xx place = calendar.place.address
          address = place.address

        else # no place, no location
          raise Problem.new('N/A')
        end
      end

    else
      raise Problem.new("Calendar import strategy unknown! (#{calendar.strategy})")
    end

    data.place_id = place.id if place
    data.address_id = address&.id
  end
  
  def save_all_occurences
    calendar_events = calendar.events.upcoming.where(uid: data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurences.map(&:start_time), occurences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurences.each do |occurence|
      # Skip if occurence is longer than 1 day
      next if occurence.end_time && (occurence.end_time.to_date - occurence.start_time.to_date).to_i > 1

      event_time = { dtstart: occurence.start_time, dtend: occurence.end_time }
      event = nil

      if calendar_events.present?
        if data.recurring_event?
          event = calendar_events.find_by(event_time)
        else 
          event = calendar_events.first
        end
      end

      event ||= calendar.events.new

      event_time[:are_spaces_available] = occurence.status if occurence.respond_to?(:status)

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
