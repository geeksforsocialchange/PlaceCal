# frozen_string_literal: true

class HeroSectionComponent < ViewComponent::Base
  def initialize(image_path:, image_credit:, title:)
    super
    @title = title.empty? ? 'PlaceCal is a community events calendar where you can find everything near you, all in one place.' : title
    @image_path = image_path
    @image_credit = image_credit
  end
end
