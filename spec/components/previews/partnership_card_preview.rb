# frozen_string_literal: true

class PartnershipCardPreview < Lookbook::Preview
  # @label Default
  def default
    site = Site.new(
      name: "Hulme & Moss Side",
      tagline: "Community events in south Manchester",
      url: "https://hulme.placecal.org/"
    )
    render Components::PartnershipCard.new(site: site)
  end
end
