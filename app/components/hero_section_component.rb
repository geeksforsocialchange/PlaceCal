# frozen_string_literal: true

class HeroSectionComponent < ViewComponent::Base
  def initialize(image_path:, image_credit:, title:)
    super
    @title = title.presence || 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
    @image_path = image_path
    @image_credit = image_credit
  end
end
