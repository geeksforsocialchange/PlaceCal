module MapMarkers
  extend ActiveSupport::Concern

  # Takes an array of Partners, Addresses or Events and returns a sanitized json
  # array suitable for creating map markers. Does not check for duplicates.
  #
  # parameters:
  #   @locations - Array of Partners, Addresses or Events
  #   @addresses_only - boolean whether to skip partners that
  #     have no service areas
  #
  # returns:
  #   Array of Hashes to be consumed by the JS map front end
  #
  def get_map_markers(locations, addresses_only=false)

    # Events
    locations = locations.map do |loc|
      next loc unless loc.is_a?(Event)

      loc.place || loc.address
    end

    # Partners
    locations = locations.map do |loc|
      next loc unless loc.is_a?(Partner)

      # reject partner with no resolvable address
      next if loc.address&.latitude&.blank?

      if addresses_only
        # reject partner if they have no service areas?
        next if loc.service_areas.count == 0
      end

      {
        lat: loc.address.latitude,
        lon: loc.address.longitude,
        name: loc.name,
        id: loc.id
      }
    end

    # Addresses
    locations = locations.map do |loc|
      next loc unless loc.is_a?(Address)
      {
        lat: loc.latitude,
        lon: loc.longitude
      }
    end

    locations.keep_if { |loc|
      # puts loc.class
      loc.is_a?(Hash) }
  end

  # Takes a reducible collection of events and returns json map markers.
  # Removes duplicate locations.
  def get_map_markers_from_events(events)
    get_map_markers(
      @events.reduce([]) do |arr, e|
        loc = e.place || e.address
        if loc then arr << loc else arr end
      end.uniq
    )
  end
end
