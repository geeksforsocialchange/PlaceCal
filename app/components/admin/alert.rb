# frozen_string_literal: true

class Components::Admin::Alert < Components::Admin::Base
  TYPES = {
    notice: { class: 'alert-info', icon: :info },
    success: { class: 'alert-success', icon: :check_circle },
    alert: { class: 'alert-warning', icon: :warning },
    error: { class: 'alert-error', icon: :x_circle },
    danger: { class: 'alert-error', icon: :x_circle }
  }.freeze

  prop :type, _Any
  prop :message, _Any

  def after_initialize
    @type = @type.to_sym
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
