# frozen_string_literal: true

module Admin
  class DangerZoneComponent < ViewComponent::Base
    include SvgIconsHelper

    # rubocop:disable Metrics/ParameterLists
    def initialize(title:, description:, button_text:, button_path:, button_method: :delete, confirm: nil)
      super()
      @title = title
      @description = description
      @button_text = button_text
      @button_path = button_path
      @button_method = button_method
      @confirm = confirm
    end
    # rubocop:enable Metrics/ParameterLists

    attr_reader :title, :description, :button_text, :button_path, :button_method, :confirm
  end
end
