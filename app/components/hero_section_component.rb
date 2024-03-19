# frozen_string_literal: true

class HeroSectionComponent < ViewComponent::Base
  def initialize(title:, image_path:, image_credit:)
    super
    @title = title
    @image_path = image_path
    @image_credit = image_credit
  end
end
