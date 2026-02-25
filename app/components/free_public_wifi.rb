# frozen_string_literal: true

class FreePublicWifi < ViewComponent::Base
  include SvgImagesHelper

  def initialize(places)
    super()
    @places = places
  end
end
