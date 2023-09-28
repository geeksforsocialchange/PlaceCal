# frozen_string_literal: true

# app/components/place/place_partner_preview_component.rb
class PlacePartnerPreviewComponent < MountainView::Presenter
  properties :primary_neighbourhood, :previewee, :show_neighbourhoods,
             :service_areas, :neighbourhood_name

  delegate :name, to: :previewee

  def link
    previewee
  end

  def show_service_area?
    service_areas.any?
  end

  def show_neighbourhood?
    show_neighbourhoods
  end

  def description
    previewee.summary
  end

  def primary_neighbourhood?
    # Show everything as primary if primary is not set
    return true unless primary_neighbourhood

    primary_neighbourhood && (previewee.address&.neighbourhood == primary_neighbourhood)
  end

  def neighbourhood_name
    properties[:neighbourhood_name]
  end

  private

  def previewee
    properties[:previewee]
  end

  def primary_neighbourhood
    properties[:primary_neighbourhood]
  end
end
