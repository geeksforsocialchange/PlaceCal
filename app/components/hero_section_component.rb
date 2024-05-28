# frozen_string_literal: true

class HeroSectionComponent < ViewComponent::Base
  def initialize(image_path:, image_credit:, title:, alttext:)
    super
    # TODO: remove hard coded string from component
    @title = title.presence || "PlaceCal is a community events calendar where you can find out everything that's happening, all in one place."
    @image_path = image_path
    @alttext = alttext
    @image_credit = image_credit
  end
end
