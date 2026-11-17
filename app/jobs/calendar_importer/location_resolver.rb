# frozen_string_literal: true

# Works out an imported event's place (a partner) and address from the calendar's location strategy.
# See doc/importing.md for how each strategy places an event.
class CalendarImporter::LocationResolver
  # Raised when the calendar's settings can't place the event; the import records the message as a notice
  class Problem < StandardError; end

  STRATEGIES = {
    'event' => :event_strategy,
    'event_override' => :event_override_strategy,
    'place' => :place_strategy,
    'room_number' => :room_number_strategy,
    'no_location' => :no_location_strategy,
    'online_only' => :no_location_strategy
  }.freeze

  # A location that is only a link is a meeting or a webpage, not an unreadable street address
  ONLINE_LINK = %r{\Ahttps?://\S+\z}i

  # The location text split on ", " with the postcode removed, e.g.
  # "Age UK Hall, 1 Duke Street, Manchester M1 2AB" with postcode "M1 2AB" gives ["Age UK Hall", "1 Duke Street", "Manchester"].
  # @return [Array<String>]
  def self.location_components(location, postcode)
    postcode = postcode.to_s.strip
    postcode_pattern = /\b#{Regexp.escape(postcode)}\b/i if postcode.present?

    location.to_s
            .split(', ')
            .map { |component| postcode_pattern ? component.gsub(postcode_pattern, '').strip : component.strip }
            .compact_blank
  end

  # @return [Symbol, nil] why the event's location text couldn't be read as an address (see Address.build_from_components_with_reason)
  attr_reader :unreadable_address_reason

  # @param calendar [Calendar] the calendar being imported, whose strategy and default venue apply
  # @param event_data [CalendarImporter::Events::Base] the event as read from the feed
  def initialize(calendar, event_data)
    @calendar = calendar
    @event_data = event_data
  end

  # @return [Array(Partner, Address)] the event's place and address; either may be nil
  # @raise [Problem] when the strategy needs a default venue the calendar doesn't have
  def resolve
    strategy_method = STRATEGIES[calendar.strategy]
    raise "Calendar import strategy unknown! (ID=#{calendar.id}, strategy=#{calendar.strategy})" unless strategy_method

    send(strategy_method)
  end

  private

  attr_reader :calendar, :event_data

  # The event's own address, with a venue only if a partner is at that address.
  # @return [Array(Partner, Address)] when the address is a partner's
  # @return [Array(nil, Address)] when it isn't, or [nil, nil] when the address can't be read
  # @return [Array(Partner, nil)] the default venue with no address, when the event has no location
  def event_strategy
    return [calendar.place, nil] unless event_data.location?

    address = event_address
    [Partner.matching_venue_for(address), address]
  end

  # The event's own address, with a venue only if a partner or the default venue is at that address.
  # With no usable address, the event is placed at the calendar's default venue.
  # @return [Array(Partner, Address)] when the address is a partner's or the default venue's, or unusable
  # @return [Array(nil, Address)] when the event is somewhere with no partner
  def event_override_strategy
    address = event_address
    return place_strategy unless address

    venue = Partner.matching_venue_for(address)
    return [venue, address] if venue
    return place_strategy if address.same_building_as?(calendar.place&.address)

    [nil, address]
  end

  # @return [Array(Partner, Address)] the calendar's default venue and its address, each nil if unset
  def place_strategy
    [calendar.place, calendar.place&.address]
  end

  # The default venue, with the event's location text added as a room on the venue's address.
  # @return [Array(Partner, Address)] the venue and a new address for the room, or the venue's own address
  # @raise [Problem] when the calendar has no default venue
  def room_number_strategy
    place = calendar.place
    raise Problem, I18n.t('admin.calendars.importer.room_number_without_venue') if place.blank?
    return [place, place.address] unless event_data.location? && place.address && !location_is_link?

    address = place.address.dup.prepend_room_number(event_data.location)
    address.save
    [place, address]
  end

  # @return [Array(nil, nil)]
  def no_location_strategy
    [nil, nil]
  end

  # @return [Address, nil] the event's location text as a saved address, or nil if missing or invalid
  def event_address
    return unless event_data.location?

    address, reason = Address.build_from_components_with_reason(event_location_components, event_data.postcode)
    @unreadable_address_reason = reason unless location_is_link?
    address
  end

  def location_is_link?
    event_data.location.to_s.strip.match?(ONLINE_LINK)
  end

  # @return [Array<String>]
  def event_location_components
    @event_location_components ||= self.class.location_components(event_data.location, event_data.postcode)
  end
end
