# frozen_string_literal: true

class Components::Admin::Flash < Components::Admin::Base
  prop :flash_messages, _Nilable(Hash), default: nil

  def view_template
    messages = @flash_messages || flash
    return unless messages.any?

    div(class: 'space-y-3 mb-3') do
      messages.each do |key, value|
        Alert(type: key, message: value)
      end
    end
  end
end
