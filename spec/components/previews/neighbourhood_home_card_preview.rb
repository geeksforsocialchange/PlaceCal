# frozen_string_literal: true

class NeighbourhoodHomeCardPreview < Lookbook::Preview
  # @label Default
  def default
    site = Site.new(
      name: "Hulme & Moss Side",
      slug: "hulme-moss-side",
      place_name: "Hulme & Moss Side"
    )
    render Components::NeighbourhoodHomeCard.new(site: site)
  end
end
