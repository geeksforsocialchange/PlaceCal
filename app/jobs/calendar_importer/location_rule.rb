# frozen_string_literal: true

# Places an event from its location text and its calendar's default location:
# the event's own valid address first, then the default location, then nothing.
class CalendarImporter::LocationRule
  Result = CalendarImporter::LocationResolver::Result

  # @return [Symbol, nil] why the location text couldn't be read as an address (see Address.build_from_components_with_reason)
  attr_reader :unreadable_address_reason

  # @param location [String, nil] the event's location text
  # @param postcode [String, nil] the postcode found in the location text
  # @param default_location [Partner, nil] the calendar's default location
  # @param room_number [Boolean] the location text is a room at the default location, never an address
  # @param save [Boolean] false builds addresses without saving them
  def initialize(location:, postcode:, default_location: nil, room_number: false, save: true)
    @location = location.to_s
    @postcode = postcode
    @default_location = default_location
    @room_number = room_number
    @save = save
  end

  # @return [Result] the place and address, either of which may be nil, and which case applied
  def result
    @result ||= room_number? ? room : own_address_or_default
  end

  private

  attr_reader :location, :postcode, :default_location

  # Without a default location there is no building for the room to be in
  def room_number?
    @room_number && default_location.present?
  end

  def room
    building = default_location.address
    return default_location_result if location.blank? || building.nil? || link?

    address = building.dup.prepend_room_number(location)
    address.save if @save
    Result.new(place: default_location, address:, match: :room)
  end

  def own_address_or_default
    address = event_address
    return default_location_result unless address

    venue = Partner.matching_venue_for(address)
    return Result.new(place: venue, address:, match: :matched_venue) if venue
    # A feed that gives its own venue's address still shows the default location's name
    return default_location_result if address.same_building_as?(default_location&.address)

    Result.new(place: nil, address:, match: :event_address)
  end

  def default_location_result
    return Result.new(place: nil, address: nil, match: :none) unless default_location

    Result.new(place: default_location, address: default_location.address, match: :default_location)
  end

  def event_address
    return if location.blank?

    components = CalendarImporter::LocationResolver.location_components(location, postcode)
    address, reason = Address.build_from_components_with_reason(components, postcode, save: @save)
    @unreadable_address_reason = reason unless link?
    address
  end

  def link?
    location.strip.match?(CalendarImporter::LocationResolver::ONLINE_LINK)
  end
end
