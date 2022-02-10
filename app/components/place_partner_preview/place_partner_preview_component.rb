# frozen_string_literal: true

# app/components/place/place_partner_preview_component.rb
class PlacePartnerPreviewComponent < MountainView::Presenter
  properties :primary_neighbourhood, :previewee, :show_neighbourhoods, :badge_zoom_level

  def name
    previewee.name
  end

  def link
    previewee
  end

  def neighbourhood_name(badge_zoom_level)
    return previewee.address&.neighbourhood&.district&.shortname if badge_zoom_level == 'district'

    previewee.address&.neighbourhood&.shortname
  end

  def description
    previewee.summary
  end

  def primary_neighbourhood?
    # Show everything as primary if primary is not set
    return true unless primary_neighbourhood
    primary_neighbourhood && (previewee.address&.neighbourhood == primary_neighbourhood)
  end

  private

  def previewee
    properties[:previewee]
  end

  def primary_neighbourhood
    properties[:primary_neighbourhood]
  end
end
