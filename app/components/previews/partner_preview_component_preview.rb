# frozen_string_literal: true

class PartnerPreviewComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    neighbourhood = OpenStruct.new(
      id: 1,
      name: 'Hulme'
    )

    address = OpenStruct.new(
      street_address: '123 High Street',
      neighbourhood: neighbourhood
    )

    partner = OpenStruct.new(
      name: 'Hulme Community Garden Centre',
      slug: 'hulme-community-garden-centre',
      summary: 'A community garden centre offering workshops, events, and green space.',
      address: address,
      neighbourhoods: [neighbourhood],
      neighbourhood_name_for_site: ->(_zoom) { 'Hulme' }
    )

    site = OpenStruct.new(
      name: 'PlaceCal Manchester',
      show_neighbourhoods?: true,
      badge_zoom_level: 10,
      primary_neighbourhood: nil
    )

    render(PartnerPreviewComponent.new(partner: partner, site: site))
  end

  # @label Without Neighbourhood
  def without_neighbourhood
    partner = OpenStruct.new(
      name: 'Online Service',
      slug: 'online-service',
      summary: 'A digital-only community service.',
      address: nil,
      neighbourhoods: [],
      neighbourhood_name_for_site: ->(_) {}
    )

    site = OpenStruct.new(
      name: 'PlaceCal Manchester',
      show_neighbourhoods?: false,
      badge_zoom_level: 10,
      primary_neighbourhood: nil
    )

    render(PartnerPreviewComponent.new(partner: partner, site: site))
  end
end
