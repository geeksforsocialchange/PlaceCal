# frozen_string_literal: true

class FlashComponent < ViewComponent::Base
  def initialize(flash: nil)
    super()
    @flash = flash
  end

  def flash
    @flash || helpers.flash
  end

  def render?
    flash.any?
  end

  def alert_class(key)
    case key.to_sym
    when :danger, :alert, :error then 'alert-danger'
    else 'alert-success'
    end
  end
end
