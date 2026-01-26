# frozen_string_literal: true

class PartnershipCardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    site = OpenStruct.new(
      name: 'Hulme & Moss Side',
      tagline: 'Community events in Hulme and Moss Side',
      url: 'https://hulme.placecal.org/',
      logo: OpenStruct.new(url: nil)
    )
    render(PartnershipCardComponent.new(site: site))
  end

  # @label With Logo
  def with_logo
    site = OpenStruct.new(
      name: 'The Trans Dimension',
      tagline: 'Trans community events in London',
      url: 'https://transdimension.uk',
      logo: OpenStruct.new(url: '/images/trans-dimension-logo.png')
    )
    render(PartnershipCardComponent.new(site: site))
  end
end
