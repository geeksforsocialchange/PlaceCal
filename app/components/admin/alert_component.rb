# frozen_string_literal: true

module Admin
  class AlertComponent < ViewComponent::Base
    include SvgIconsHelper

    TYPES = {
      notice: { class: 'alert-info', icon: :info },
      success: { class: 'alert-success', icon: :check_circle },
      alert: { class: 'alert-warning', icon: :warning },
      error: { class: 'alert-error', icon: :x_circle }
    }.freeze

    def initialize(type:, message:)
      super
      @type = type.to_sym
      @message = message
    end

    private

    def alert_class
      TYPES.dig(@type, :class) || TYPES[:notice][:class]
    end

    def icon_name
      TYPES.dig(@type, :icon) || TYPES[:notice][:icon]
    end
  end
end
