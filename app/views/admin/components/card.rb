# frozen_string_literal: true

class Views::Admin::Components::Card < Views::Admin::Components::Base
  VARIANTS = {
    default: 'bg-base-100 border-base-300',
    success: 'bg-success/5 border-success/20',
    error: 'bg-error/5 border-error/20',
    warning: 'bg-warning/5 border-warning/20',
    orange: 'bg-gradient-to-br from-placecal-orange/5 via-base-100 to-base-100 border-base-300',
    purple: 'bg-gradient-to-br from-purple-500/5 via-base-100 to-base-100 border-base-300'
  }.freeze

  def initialize(title: nil, icon: nil, icon_class: nil, variant: :default, header_link: nil, header_link_text: nil, decorative_blur: nil) # rubocop:disable Metrics/ParameterLists
    @title = title
    @icon = icon
    @icon_class = icon_class || 'text-placecal-orange'
    @variant = variant
    @header_link = header_link
    @header_link_text = header_link_text
    @decorative_blur = decorative_blur
    @header_block = nil
    @header_action_block = nil
    @body_block = nil
  end

  def with_header(&block)
    @header_block = block
    self
  end

  def with_header_action(&block)
    @header_action_block = block
    self
  end

  def with_body(&block)
    @body_block = block
    self
  end

  def view_template(&content_block)
    div(class: "card #{variant_classes} border shadow-sm overflow-hidden relative") do
      render_decorative_blur
      div(class: 'card-body p-4 relative') do
        render_header_section
        if @body_block
          @body_block.call
        elsif content_block
          yield
        end
      end
    end
  end

  private

  def variant_classes
    VARIANTS[@variant] || VARIANTS[:default]
  end

  def render_decorative_blur
    return unless @decorative_blur && blur_position_classes && blur_color

    div(class: "absolute #{blur_position_classes} w-32 h-32 #{blur_color} rounded-full blur-2xl")
  end

  def render_header_section
    has_header = @title || @header_block || @header_action_block || @header_link
    return unless has_header

    div(class: 'flex items-center justify-between mb-3') do
      if @header_block
        @header_block.call
      elsif @title
        h2(class: 'font-bold flex items-center gap-2') do
          icon(@icon, size: '5', css_class: @icon_class) if @icon
          plain @title
        end
      end

      if @header_action_block
        @header_action_block.call
      elsif @header_link
        link_to(@header_link_text || t('admin.actions.view_all'), @header_link,
                class: 'text-sm text-placecal-orange-dark underline hover:no-underline')
      end
    end
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
