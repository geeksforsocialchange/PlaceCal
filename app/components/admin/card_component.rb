# frozen_string_literal: true

module Admin
  class CardComponent < ViewComponent::Base
    renders_one :header
    renders_one :header_action
    renders_one :body

    VARIANTS = {
      default: 'bg-base-100 border-base-300',
      success: 'bg-success/5 border-success/20',
      error: 'bg-error/5 border-error/20',
      warning: 'bg-warning/5 border-warning/20',
      orange: 'bg-gradient-to-br from-placecal-orange/5 via-base-100 to-base-100 border-base-300',
      purple: 'bg-gradient-to-br from-purple-500/5 via-base-100 to-base-100 border-base-300'
    }.freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(title: nil, icon: nil, icon_class: nil, variant: :default, header_link: nil, header_link_text: nil, decorative_blur: nil)
      super()
      @title = title
      @icon = icon
      @icon_class = icon_class || 'text-placecal-orange'
      @variant = variant
      @header_link = header_link
      @header_link_text = header_link_text
      @decorative_blur = decorative_blur
    end
    # rubocop:enable Metrics/ParameterLists

    def variant_classes
      VARIANTS[@variant] || VARIANTS[:default]
    end

    def blur_position_classes
      case @decorative_blur
      when :top_right then '-right-8 -top-8'
      when :bottom_left then '-left-8 -bottom-8'
      end
    end

    def blur_color
      case @variant
      when :orange then 'bg-placecal-orange/10'
      when :purple then 'bg-purple-500/10'
      end
    end
  end
end
