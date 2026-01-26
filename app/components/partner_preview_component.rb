# frozen_string_literal: true

class PartnerPreviewComponent < ViewComponent::Base
  def initialize(partner:, site:)
    super()
    @partner = partner
    @site = site
  end

  # Should this partner show a neighbourhood lozenge?
  def show_neighbourhood?
    @site.show_neighbourhoods? || @partner.neighbourhoods.any?
  end

  def neighbourhood_name
    @partner.neighbourhood_name_for_site(@site.badge_zoom_level)
  end

  # If the neighbourhood is the site's primary one, show the lozenge in a different colour
  def primary_neighbourhood?
    # Show everything as primary if primary is not set
    return true unless @site.primary_neighbourhood

    @site.primary_neighbourhood && (@partner.address&.neighbourhood == @site.primary_neighbourhood)
  end
end
