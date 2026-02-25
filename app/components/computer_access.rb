# frozen_string_literal: true

class ComputerAccess < ViewComponent::Base
  include SvgImagesHelper

  def initialize(places)
    super()
    @places = places
  end
end
