# frozen_string_literal: true

class FreePublicWifi < ViewComponent::Base
  def initialize(places)
    super()
    @places = places
  end
end
