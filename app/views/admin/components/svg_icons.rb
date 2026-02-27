# frozen_string_literal: true

# Phlex-native SVG icon rendering, reusing constants from SvgIconsHelper
module Views::Admin::Components::SvgIcons
  # Render an SVG icon using Phlex DSL
  # @param name [Symbol] Icon name from SvgIconsHelper::ICONS
  # @param size [String] Tailwind size (e.g., "4", "5", "8")
  # @param css_class [String] Additional CSS classes
  # @param stroke_width [String] SVG stroke width (default: "2")
  def icon(name, size: '5', css_class: '', stroke_width: '2')
    path_data = SvgIconsHelper::ICONS[name.to_sym]
    unless path_data
      span(class: 'text-error') { "[icon:#{name}]" }
      return
    end

    size_class = SvgIconsHelper::SIZE_CLASSES[size.to_s] || "w-#{size} h-#{size}"
    classes = css_class.present? ? "#{size_class} #{css_class}" : size_class

    svg(
      class: classes,
      fill: 'none',
      stroke: 'currentColor',
      viewBox: '0 0 24 24'
    ) do |s|
      s.path(
        stroke_linecap: 'round',
        stroke_linejoin: 'round',
        stroke_width: stroke_width,
        d: path_data
      )
    end
  end
end
