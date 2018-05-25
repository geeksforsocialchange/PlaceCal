# frozen_string_literal: true

# app/components/hero_image/hero_image_component.rb
class HeroImageComponent < MountainView::Presenter
  property :title, default: 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
  properties :image_path, :image_credit

  def title
    properties[:title]
  end

  def image_credit
    return false unless properties[:image_credit]
    "Image credit: #{properties[:image_credit]}"
  end

  def bg_image_path
    "url(#{image_path})"
  end
end
