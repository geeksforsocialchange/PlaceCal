# frozen_string_literal: true

class HeroImageComponent < ViewComponent::Base
  def initialize(
    image_path:,
    image_credit:,
    title: 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
  )
    super
    @title = title
    @bg_image_path = "url(#{image_path})"
    @image_credit = image_credit.blank? ? false : "Image credit: #{image_credit}"
  end
end
