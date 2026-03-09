# frozen_string_literal: true

# Determines place and address for an event based on the calendar's location strategy.
#
# Given a calendar strategy and event data, returns [place, address].
# See doc/importing.md for strategy documentation.
class CalendarImporter::LocationResolver
  class Problem < StandardError; end

  def initialize(calendar, event_data)
    @calendar = calendar
    @event_data = event_data
  end

  # @return [Array(Partner, Address)] the resolved [place, address] pair
  def resolve
    strategy_method = STRATEGIES[calendar.strategy]
    raise "Calendar import strategy unknown! (ID=#{calendar.id}, strategy=#{calendar.strategy})" unless strategy_method

    send(strategy_method)
  end

  STRATEGIES = {
    'event' => :event_strategy,
    'event_override' => :event_override_strategy,
    'place' => :place_strategy,
    'room_number' => :room_number_strategy,
    'no_location' => :no_location_strategy,
    'online_only' => :online_only_strategy
  }.freeze

  private

  attr_reader :calendar, :event_data

  def event_strategy
    if event_data.has_location?
      address = Address.build_from_components(event_location_components, event_data.postcode)
      place = Partner.matching_venue_for(address)
      [place, address]
    else
      [calendar.place, nil]
    end
  end

  def event_override_strategy
    # Fall back to calendar's place when the event has no location or address can't be built
    return [calendar.place, calendar.place&.address] unless event_data.has_location?

    address = Address.build_from_components(event_location_components, event_data.postcode)
    return [calendar.place, calendar.place&.address] unless address

    place = Partner.matching_venue_for(address) || calendar.place
    [place, address]
  end

  def place_strategy
    [calendar.place, calendar.place&.address]
  end

  def room_number_strategy
    place = calendar.place
    raise Problem, 'N/A' if place.blank?

    if event_data.has_location?
      new_address = place.address.dup
      address = new_address.prepend_room_number(event_data.location)
      address.save
      [place, address]
    else
      [place, place.address]
    end
  end

  def no_location_strategy
    [nil, nil]
  end

  def online_only_strategy
    [nil, nil]
  end

  def event_location_components
    @event_location_components ||= begin
      regex_string = 'UK|United Kingdom'
      regex_string += "|#{event_data.postcode.strip}" if event_data.postcode.present?

      regexp = Regexp.new(regex_string, Regexp::IGNORECASE)

      (event_data.location || '')
        .split(', ')
        .map { |component| component.gsub(regexp, '').strip }
        .compact_blank
    end
  end
end
