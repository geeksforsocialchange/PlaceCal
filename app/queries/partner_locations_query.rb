# frozen_string_literal: true

# Builds the marker data for the directory's nationwide partner map.
#
# Partners with a geocoded address are plotted at their own coordinates.
# Address-less partners are plotted at the centroid of their most specific
# service-area neighbourhood (falling back to that neighbourhood's descendants),
# so service-only partners still appear on the map.
#
# Returns plain hashes with a partner +slug+ rather than a URL — building the
# route belongs to the controller/view layer, not the query.
#
# @example
#   PartnerLocationsQuery.new.call
#   # => [{ lat: 53.4, lon: -2.2, name: "Some Partner", slug: "some-partner" }, ...]
#
class PartnerLocationsQuery
  # Service-area neighbourhood units from most to least specific. A partner is
  # placed at its smallest available unit.
  NEIGHBOURHOOD_UNIT_RANK = %w[ward district county region].freeze

  # @return [Array<Hash>] { lat:, lon:, name:, slug: } for each mappable partner
  def call
    located_partners + service_area_partners
  end

  private

  def located_partners
    Partner.visible.joins(:address)
           .where.not(addresses: { latitude: nil })
           .pluck(:name, :slug, 'addresses.latitude', 'addresses.longitude')
           .map { |name, slug, lat, lon| { lat: lat, lon: lon, name: name, slug: slug } }
  end

  def service_area_partners
    addressless = Partner.visible.where(address_id: nil).includes(service_areas: :neighbourhood)
    return [] if addressless.none?

    centroids = neighbourhood_centroids(service_area_neighbourhood_ids(addressless))

    addressless.filter_map do |partner|
      neighbourhood = best_service_area_neighbourhood(partner)
      next unless neighbourhood

      coords = centroids[neighbourhood.id]
      next unless coords

      { lat: coords[0], lon: coords[1], name: partner.name, slug: partner.slug }
    end
  end

  def service_area_neighbourhood_ids(partners)
    partners.flat_map { |p| p.service_areas.map(&:neighbourhood_id) }.compact.uniq
  end

  # The most specific service-area neighbourhood we know how to place.
  def best_service_area_neighbourhood(partner)
    partner.service_areas.filter_map(&:neighbourhood)
           .select { |n| NEIGHBOURHOOD_UNIT_RANK.include?(n.unit) }
           .min_by { |n| NEIGHBOURHOOD_UNIT_RANK.index(n.unit) }
  end

  # Average address coordinates per neighbourhood, falling back to descendant
  # neighbourhoods when a neighbourhood has no addresses of its own.
  def neighbourhood_centroids(neighbourhood_ids)
    cache = {}
    Neighbourhood.where(id: neighbourhood_ids).find_each do |n|
      addrs = Address.where(neighbourhood_id: n.id).where.not(latitude: nil)
      unless addrs.exists?
        desc_ids = n.descendant_ids
        addrs = Address.where(neighbourhood_id: desc_ids).where.not(latitude: nil) if desc_ids.any?
      end
      next unless addrs.exists?

      cache[n.id] = [addrs.average(:latitude).to_f, addrs.average(:longitude).to_f]
    end
    cache
  end
end
