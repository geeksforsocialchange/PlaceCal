# frozen_string_literal: true

class PartnerPreviewPreview < Lookbook::Preview
  # @label Default
  # @notes Uses unsaved AR models. Some association-dependent features
  # (neighbourhood badges) may not render fully without seed data.
  def default
    partner = Partner.new(
      name: "Hulme Community Garden Centre",
      summary: "A community garden in the heart of Hulme offering workshops, volunteering, and green space for everyone.",
      description: "Full description here."
    )
    site = Site.new(
      name: "Hulme & Moss Side",
      slug: "hulme-moss-side"
    )
    render Components::PartnerPreview.new(partner: partner, site: site)
  end
end
