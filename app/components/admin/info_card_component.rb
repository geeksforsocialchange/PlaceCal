# frozen_string_literal: true

module Admin
  # A compact info card showing an icon, label, and value.
  # Used in grids on show pages to display key metrics.
  #
  # @example Basic usage
  #   <%= render Admin::InfoCardComponent.new(
  #     icon: :calendar,
  #     label: "Calendars",
  #     value: 5,
  #     color: :orange
  #   ) %>
  #
  # @example With link
  #   <%= render Admin::InfoCardComponent.new(
  #     icon: :partner,
  #     label: "Partner",
  #     color: :orange
  #   ) do %>
  #     <%= link_to @calendar.partner.name, edit_admin_partner_path(@calendar.partner), class: "font-semibold link link-hover text-placecal-orange" %>
  #   <% end %>
  #
  class InfoCardComponent < ViewComponent::Base
    include SvgIconsHelper

    COLORS = {
      orange: { bg: 'bg-placecal-orange/10', text: 'text-placecal-orange' },
      info: { bg: 'bg-info/10', text: 'text-info' },
      success: { bg: 'bg-success/10', text: 'text-success' },
      error: { bg: 'bg-error/10', text: 'text-error' },
      warning: { bg: 'bg-warning/10', text: 'text-warning' },
      neutral: { bg: 'bg-base-300', text: 'text-base-content/30' }
    }.freeze

    # @param icon [Symbol] Icon name from SvgIconsHelper::ICONS
    # @param label [String] Label text (shown as uppercase small text)
    # @param value [String, Integer, nil] Value to display (optional if using block)
    # @param color [Symbol] Color theme (:orange, :info, :success, :error, :warning, :neutral)
    def initialize(icon:, label:, value: nil, color: :orange)
      super()
      @icon = icon
      @label = label
      @value = value
      @color = color
    end

    private

    attr_reader :icon, :label, :value, :color

    def icon_bg_class
      COLORS.dig(color, :bg) || COLORS[:orange][:bg]
    end

    def icon_text_class
      COLORS.dig(color, :text) || COLORS[:orange][:text]
    end
  end
end
