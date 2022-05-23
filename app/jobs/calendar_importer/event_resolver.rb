# frozen_string_literal: true

class CalendarImporter::EventResolver
  WARNING1_MSG = 'Could not determine where this event is. Add an address to the location field of the source ' \
                 'calendar, or choose another import strategy with a default location'
  WARNING2_MSG = 'Could not determine where this event is. A default location is set but the importer is set '  \
                 'to ignore this. Add an address to the location field of the source calendar, or choose '      \
                 'another import strategy with a default location.'
  INFO1_MSG = 'This location was not recognised by PlaceCal, woulfd you like to add it?'

  attr_reader :data, :uid, :notices, :calendar

  class Problem < StandardError; end

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
    # this algorithm is derived from the notion doc at
    #   GFSC
    #     PlaceCal
    #       PlaceCal Handbook
    #         PlaceCal developer handbook
    #           How does the Calendar importer detect Places and Addresses?

    strategies = {
      'event' => :event_strategy,
      'event_override' => :event_override_strategy,
      'place' => :place_strategy,
      'room_number' => :room_number_strategy,
      'no_location' => :no_location_strategy,
      'online_only' => :online_only_strategy
    }

    if strategies.keys.include?(calendar.strategy)
      strategy = strategies[calendar.strategy]
      place, address = method(strategy).call(calendar.place)
    else
      # this shouldn't happen and should be fatal to the entire job
      raise "Calendar import strategy unknown! (ID=#{calendar.id}, strategy=#{calendar.strategy})"
    end

    data.place_id = place.id if place
    data.address_id = address&.id
    data.partner_id = calendar.partner_id
  end

  def event_strategy(place, address: nil)
    if data.has_location?
      # place = 'attempt to match location'
      # address = 'calendar.place.address || location'

      # try to find the place
      place = Partner.fuzzy_find_by_location(event_location_components)

      # try to use that address
      address = place&.address

      # if no place, try to find an address
      # (This only executes if there is no place given)
      address ||= Address.search(data.location, event_location_components, data.postcode)

      # if we have an address, try to use the place that address points to
      # (Only runs if the fuzzy find and calendar.place are both nil)
      place ||= address&.partners&.first

      # NOTE: What happens if address has zero partners and the earlier assignments fail?
      #       'place' is nil in this instance
      # NOTE: Address.search can also return Nil if there are no event_location_components, or
      #       if the address failed to save
      # Both of these will cause the event to fail validation with "No place or address could be created/found (etc)"

    else # no location
      raise Problem, WARNING2_MSG if place.present?
      # No longer an error if place is not present -- see #1198
      # Passthrough here
    end

    return place, address
  end

  def event_override_strategy(place, address: nil)
    if data.has_location?
      # place = 'attempt to match location'
      # address = 'calendar.place.address || location'
      place = Partner.fuzzy_find_by_location(event_location_components)
      address = place&.address
      address ||= Address.search(data.location, event_location_components, data.postcode)

      raise Problem, INFO1_MSG if place.nil? && address.nil?

      # NOTE: Either one of 'place' or 'address' is unset here but not both
      # NOTE: place is possibly unset here - fuzzy_find_by_location can be nil
      # NOTE: address is possibly unset here - place might be nil or Address.search can return nil
      #       In either case we will just drop this event on the floor
    else # no location
      if place.present?
        # place = 'calendar.place'
        # address = 'calendar.place.address'
        place = calendar.place
        address = place.address

      else # no place, no location
        raise Problem, WARNING1_MSG
      end
    end

    return place, address
  end

  def place_strategy(_place, _address: nil)
    # Regardless of if the data has a location, we act the same
    # We assign address to the place's address if possible, and otherwise we exit

    # This should theoretically never run ! :) (At least, it's not accounted for in Kim's table)
    raise Problem, 'N/A - Unaccounted for in table' if calendar.place.nil?

    return calendar.place, calendar.place.address

    # NOTE: calendar.place can be nil, in which case this event will be dropped on the floor
    #       (Likely what is happening with Velociposse?)
  end

  def room_number_strategy(place, address: nil)
    if data.has_location?
      if place.present?
        # place = 'calendar.place'
        # address = '#{location}, place.address'

        # xx place = calendar.place.address
        new_address = place.address.dup
        address = new_address.prepend_room_number(data.location)
        address.save

      else # no place, yes location
        raise Problem, 'N/A'
      end

    else # no location
      if place.present?
        # place = 'calendar.place'
        # address = 'calendar.place.address'
        # xx place = calendar.place.address
        address = place.address

      else # no place, no location
        raise Problem, 'N/A'
      end
    end

    return address, place
  end

  def no_location_strategy(_place, _address: nil)
    return nil, nil
  end

  def online_only_strategy(_place, _address: nil)
    return nil, nil
  end

  def save_all_occurences
    calendar_events = calendar.events.upcoming.where(uid: data.uid)

    # If any dates of this event don't match the imported start times or end times, delete them
    if data.recurring_event?
      events_with_invalid_dates = calendar_events.without_matching_times(occurences.map(&:start_time),
                                                                         occurences.map(&:end_time))
      events_with_invalid_dates.destroy_all
    end

    occurences.each do |occurence|
      event_time = { dtstart: occurence.start_time, dtend: occurence.end_time }
      event = nil

      if calendar_events.present?
        event = if data.recurring_event?
                  calendar_events.find_by(event_time)
                else
                  calendar_events.first
                end
      end

      event ||= calendar.events.new

      event_time[:are_spaces_available] = occurence.status if occurence.respond_to?(:status)

      unless event.update data.attributes.merge(event_time)
        notices << { event: event, errors: event.errors.full_messages }
      end

      if event.address_id.blank? && calendar.strategy == 'event'
        notices << { event: event, errors: ['No place or address could be created or found for '\
                                            " the event location: #{event.raw_location_from_source}"] }
      end
    end
  end

  def event_location_components
    return @event_location_components if @event_location_components

    regex_string = 'UK|United Kingdom'
    regex_string += "|#{data.postcode.strip}" if data.postcode.present?

    regexp = Regexp.new(regex_string, Regexp::IGNORECASE)

    @event_location_components = (data.location || '')
      .split(', ')
      .map { |component| component.gsub(regexp, '').strip }
      .reject(&:blank?)
  end
end
