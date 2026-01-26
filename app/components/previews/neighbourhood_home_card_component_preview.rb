# frozen_string_literal: true

class NeighbourhoodHomeCardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    site = OpenStruct.new(
      name: 'Hulme & Moss Side',
      slug: 'hulme',
      tagline: 'Community events in Hulme and Moss Side',
      url: 'https://hulme.placecal.org',
      logo: OpenStruct.new(url: nil)
    )
    render(NeighbourhoodHomeCardComponent.new(site: site))
  end

  # @label With Logo
  def with_logo
    site = OpenStruct.new(
      name: 'The Trans Dimension',
      slug: 'trans-dimension',
      tagline: 'Trans community events in London',
      url: 'https://transdimension.uk',
      logo: OpenStruct.new(url: '/images/trans-dimension-logo.png')
    )
    render(NeighbourhoodHomeCardComponent.new(site: site))
  end
end
