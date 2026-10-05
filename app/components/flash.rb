# frozen_string_literal: true

class Components::Flash < Components::Base
  prop :flash_messages, _Nilable(Hash), default: nil

  def view_template
    messages = @flash_messages || flash
    return unless messages.any?

    div(class: 'flashes flex flex-col gap-2 my-4') do
      messages.each do |key, value|
        div(class: "flash-message flash-message--#{state(key)}", role: 'alert') { value }
      end
    end
  end

  private

  def state(key)
    case key.to_sym
    when :danger, :alert, :error then 'error'
    else 'success'
    end
  end
end
