# frozen_string_literal: true

module Admin
  class FlashComponent < ViewComponent::Base
    def initialize(flash: nil)
      super()
      @flash = flash
    end

    def flash
      @flash || helpers.flash
    end
  end
end
