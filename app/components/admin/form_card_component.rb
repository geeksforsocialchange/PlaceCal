# frozen_string_literal: true

module Admin
  # A card component for form sections with icon, title, and optional description.
  # Used throughout admin forms to group related fields.
  #
  # @example Basic usage
  #   <%= render Admin::FormCardComponent.new(icon: :map, title: "Address") do %>
  #     <%= f.input :street %>
  #   <% end %>
  #
  # @example With description
  #   <%= render Admin::FormCardComponent.new(
  #     icon: :clock,
  #     title: "Opening Times",
  #     description: "When is this location open?"
  #   ) do %>
  #     <%= render 'opening_times', f: f %>
  #   <% end %>
  #
  class FormCardComponent < ViewComponent::Base
    include SvgIconsHelper

    # @param icon [Symbol] Icon name from SvgIconsHelper::ICONS
    # @param title [String] Card title
    # @param description [String, nil] Optional description text
    # @param fit_height [Boolean] If true, card won't stretch to fill container (h-fit)
    def initialize(icon:, title:, description: nil, fit_height: false)
      super()
      @icon = icon
      @title = title
      @description = description
      @fit_height = fit_height
    end

    private

    attr_reader :icon, :title, :description, :fit_height

    def card_classes
      classes = 'card bg-base-200/50 border border-base-300'
      classes += ' h-fit' if fit_height
      classes
    end
  end
end
