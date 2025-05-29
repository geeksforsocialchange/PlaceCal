# frozen_string_literal: true

# app/components/admin_flash.rb
class AdminFlash < ViewComponent::Base
  def initialize(flash: nil)
    super
    @flash = flash
  end
end
