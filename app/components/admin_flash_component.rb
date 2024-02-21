# frozen_string_literal: true

require 'yaml'

class AdminFlashComponent < ViewComponent::Base
  attr_reader :flash
  
  def initialize(flash:)
    @flash = flash
  end
end
