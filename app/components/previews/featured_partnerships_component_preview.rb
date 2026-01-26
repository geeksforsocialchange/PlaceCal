# frozen_string_literal: true

class FeaturedPartnershipsComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    sites = [
      OpenStruct.new(
        name: 'Hulme & Moss Side',
        slug: 'hulme',
        tagline: 'Community events in Hulme',
        url: 'https://hulme.placecal.org',
        logo: OpenStruct.new(url: nil)
      ),
      OpenStruct.new(
        name: 'The Trans Dimension',
        slug: 'trans-dimension',
        tagline: 'Trans community events in London',
        url: 'https://transdimension.uk',
        logo: OpenStruct.new(url: nil)
      ),
      OpenStruct.new(
        name: 'Age Friendly Manchester',
        slug: 'age-friendly',
        tagline: 'Events for older people',
        url: 'https://agefriendly.placecal.org',
        logo: OpenStruct.new(url: nil)
      )
    ]
    render(FeaturedPartnershipsComponent.new(sites: sites))
  end
end
