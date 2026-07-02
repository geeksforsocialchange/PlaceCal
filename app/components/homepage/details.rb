# frozen_string_literal: true

# Render a collapsible HTML details element which is expanded at the `for-tablet-landscape-up` breakpoint
class Components::Homepage::Details < Components::Base
  prop :header, _Nilable(String), default: nil
  prop :summary, _Nilable(String), default: nil
  # Rich summary markup as an alternative to the +summary+ string, e.g. when the
  # summary needs emphasis or multiple paragraphs. Rendered in the component's
  # context so callers can use the Phlex DSL instead of an HTML string.
  prop :summary_content, _Nilable(Proc), default: nil
  prop :header_class, String, default: ''
  prop :header_level, Integer, default: 3
  prop :image_url, _Nilable(String), default: nil
  prop :image_alt, String, default: ''
  prop :image_layout, String, default: 'right'

  def after_initialize
    @image_layout = if @image_url
                      %w[left center right].include?(@image_layout) ? @image_layout : 'right'
                    else
                      'none'
                    end
  end

  def view_template(&block)
    details(class: "details details__image__#{@image_layout}") do
      summary do
        render_header if @header
        render_summary_content
        render_image if @image_url
        if block
          render_toggle_button
          div(class: 'details__detail', &block)
        end
      end
    end
  end

  private

  def render_header
    send(:"h#{@header_level}", class: "details__header #{@header_class}") { @header }
  end

  def render_summary_content
    div(class: 'details__summary') do
      if @summary_content
        instance_exec(&@summary_content)
      elsif @summary&.match?(/^<p/)
        raw safe(@summary)
      elsif @summary
        p { plain @summary }
      end
    end
  end

  def render_image
    image_tag(@image_url, alt: @image_alt)
  end

  def render_toggle_button
    div(class: 'btn btn--small btn--home-3') do
      raw(view_context.icon(:home_plus, size: nil, css_class: 'details__button__child__open'))
      raw(view_context.icon(:home_minus, size: nil, css_class: 'details__button__child__close'))
      span(class: 'details__button__child__open') { t('components.details.open') }
      span(class: 'details__button__child__close') { t('components.details.close') }
    end
  end
end
