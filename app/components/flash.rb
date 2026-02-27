# frozen_string_literal: true

class Components::Flash < Components::Base
  prop :flash, _Nilable(_Any), default: nil

  def view_template
    return unless flash_messages.any?

    div(class: 'flashes') do
      flash_messages.each do |key, value|
        div(class: "alert #{alert_class(key)}", role: 'alert') { value }
      end
    end
  end

  private

  def flash_messages
    @flash || helpers.flash
  end

  def alert_class(key)
    case key.to_sym
    when :danger, :alert, :error then 'alert-danger'
    else 'alert-success'
    end
  end
end
