# frozen_string_literal: true

module Admin
  class EmptyStateComponent < ViewComponent::Base
    include SvgIconsHelper

    def initialize(icon:, message:, hint: nil, icon_size: '10', padding: 'py-8')
      super()
      @icon_name = icon
      @message = message
      @hint = hint
      @icon_size = icon_size
      @padding = padding
    end

    attr_reader :icon_name, :message, :hint, :icon_size, :padding
  end
end
