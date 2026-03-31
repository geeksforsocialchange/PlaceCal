# frozen_string_literal: true

class PartnerFilterPreview < Lookbook::Preview
  # @label Placeholder
  # @notes PartnerFilter requires a Site with database records (it queries
  # PartnersQuery for categories and neighbourhoods). This preview is a
  # placeholder. To see it in action, use seed data or view it on a
  # running site at /partners.
  def placeholder
    render_with_template(template: "partner_filter_preview/placeholder")
  end
end
