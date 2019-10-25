# frozen_string_literal: true

# app/components/card/card_component.rb
class CardComponent < MountainView::Presenter
  property :title, default: false
  property :subtitle, default: false
  property :image, default: false
  property :description, default: false
  property :link, default: false
  property :last_updated, default: false
end
