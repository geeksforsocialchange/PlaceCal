# frozen_string_literal: true

class ComputerAccess < ViewComponent::Base
  def initialize(places)
    super()
    @places = places
  end
end
