# frozen_string_literal: true

# app/components/place/place_partner_preview_component.rb
class PlacePartnerPreviewComponent < MountainView::Presenter
  property :name
  property :link
  property :turf
  property :primary_turf?
  property :description
end
