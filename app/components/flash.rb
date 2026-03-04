# frozen_string_literal: true

class Components::Flash < Components::Base
  prop :flash_messages, _Nilable(Hash), default: nil

  def view_template
    messages = @flash_messages || flash
    return unless messages.any?

    div(class: 'mx-6') do
      messages.each do |key, value|
        div(class: "relative py-3 px-5 mb-4 border rounded #{alert_classes(key)}", role: 'alert') { value }
      end
    end
  end

  private

  def alert_classes(key)
    case key.to_sym
    when :danger, :alert, :error
      'text-[#721c24] bg-[#f8d7da] border-[#f5c6cb]'
    else
      'text-[#155724] bg-[#d4edda] border-[#c3e6cb]'
    end
  end
end
