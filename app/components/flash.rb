# frozen_string_literal: true

class Components::Flash < Components::Base
  prop :flash_messages, _Nilable(Hash), default: nil

  def view_template
    messages = @flash_messages || flash
    return unless messages.any?

    div(class: 'flashes') do
      messages.each do |key, value|
        div(class: "alert #{alert_class(key)}", role: 'alert') { value }
      end
    end
  end

  private

  def alert_class(key)
    case key.to_sym
    when :danger, :alert, :error then 'alert-danger'
    else 'alert-success'
    end
  end
end
