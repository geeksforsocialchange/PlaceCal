# frozen_string_literal: true

class Sites::PartnerPreviewPreview < Lookbook::Preview
  # @label Default
  # @notes Uses unsaved AR models. Some association-dependent features
  # (neighbourhood badges) may not render fully without seed data.
  def default
    partner = Partner.new(
      id: 1,
      slug: "hulme-community-garden-centre",
      name: "Hulme Community Garden Centre",
      summary: "A community garden in the heart of Hulme offering workshops, volunteering, and green space for everyone.",
      description: "Full description here."
    )
    site = Site.new(
      name: "Hulme & Moss Side",
      slug: "hulme-moss-side"
    )
    render Components::Sites::PartnerPreview.new(partner:, site:)
  end

  # @label With a neighbourhood
  def with_neighbourhood
    partner = Partner.new(
      id: 2,
      slug: "moss-side-library",
      name: "Moss Side Library",
      summary: "Books, computers and a warm space, five days a week.",
      description: "Full description here.",
      address: Address.new(neighbourhood: Neighbourhood.new(name: "Moss Side"))
    )
    render Components::Sites::PartnerPreview.new(partner:, site: Site.new(name: "Hulme & Moss Side", slug: "hulme-moss-side"))
  end
end
