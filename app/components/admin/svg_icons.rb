# frozen_string_literal: true

# Phlex wrapper for SvgIconsHelper, so admin components write icons straight into their output
module Components::Admin::SvgIcons
  def icon(name, size: '5', css_class: '')
    raw(view_context.svg_icon(name, size:, css_class:))
  end
end
