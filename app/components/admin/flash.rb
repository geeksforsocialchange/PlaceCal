# frozen_string_literal: true

class Components::Admin::Flash < Components::Admin::Base
  prop :flash, _Nilable(_Any), default: nil

  def view_template
    flash_messages = @flash || helpers.flash
    return unless flash_messages.any?

    div(class: 'space-y-3 mb-3') do
      flash_messages.each do |key, value|
        render Components::Admin::Alert.new(type: key, message: value)
      end
    end
  end
end
