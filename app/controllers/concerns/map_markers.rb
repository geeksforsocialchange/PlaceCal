# frozen_string_literal: true

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
  def get_map_markers(locations, addresses_only = false)
    # Events
    locations = locations.map do |loc|
      next loc unless loc.is_a?(Event)

      loc.partner_at_location || loc.address
    end

    # Partners
    locations = locations.map do |loc|
      next loc unless loc.is_a?(Partner)

      # reject partner with no resolvable address
      next if loc.address.nil? || loc.address.latitude.blank?

      if addresses_only && loc.service_areas.any?
        # reject partner if they have any service areas?
        next
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

    locations.keep_if { |loc| loc.is_a?(Hash) }
  end
end
