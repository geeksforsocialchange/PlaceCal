# frozen_string_literal: true

class Components::Shared::Flash < Components::Base
  STATES = { success: 'bg-primary', error: 'bg-secondary' }.freeze

  prop :flash_messages, _Nilable(Hash), default: nil

  def view_template
    messages = @flash_messages || flash
    return unless messages.any?

    div(class: 'container-public flex flex-col gap-2 pb-6', data: { flash: true }) do
      messages.each do |key, value|
        div(class: "rounded-card px-4 py-3 text-detail font-bold text-foreground-dark #{STATES[state(key)]}", role: 'alert') { value }
      end
    end
  end

  private

  def state(key)
    case key.to_sym
    when :danger, :alert, :error then :error
    else :success
    end
  end
end
