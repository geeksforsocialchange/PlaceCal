# frozen_string_literal: true

class PartnerPreviewComponent < ViewComponent::Base
  def initialize(partner:, site:)
    super
    @partner = partner
    @site = site
    @show_neighbourhoods = @site.show_neighbourhoods?
    @neighbourhood_name = @partner.neighbourhood_name_for_site(@site.badge_zoom_level)
  end

  def show_neighbourhood?
    @show_neighbourhoods || service_areas.any?
  end

  def primary_neighbourhood?
    # Show everything as primary if primary is not set
    return true unless @site.primary_neighbourhood

    @site.primary_neighbourhood && (@partner.address&.neighbourhood == @site.primary_neighbourhood)
  end

  def data_categories
    @partner.categories.pluck(:id)
  end

  def data_neighbourhoods
    @partner.neighbourhoods.pluck(:id)
  end
end
