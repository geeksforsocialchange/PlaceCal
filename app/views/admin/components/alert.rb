# frozen_string_literal: true

class Views::Admin::Components::Alert < Views::Admin::Components::Base
  TYPES = {
    notice: { class: 'alert-info', icon: :info },
    success: { class: 'alert-success', icon: :check_circle },
    alert: { class: 'alert-warning', icon: :warning },
    error: { class: 'alert-error', icon: :x_circle },
    danger: { class: 'alert-error', icon: :x_circle }
  }.freeze

  def initialize(type:, message:)
    @type = type.to_sym
    @message = message
  end

  def view_template
    div(role: 'alert', class: "alert #{alert_class} shadow-md") do
      icon(icon_name, size: '6', css_class: 'shrink-0')
      span { raw(safe(@message)) }
    end
  end

  private

  def alert_class
    TYPES.dig(@type, :class) || TYPES[:notice][:class]
  end

  def icon_name
    TYPES.dig(@type, :icon) || TYPES[:notice][:icon]
  end
end
