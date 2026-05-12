# frozen_string_literal: true

# Phlex-native SVG icon rendering, reusing constants from SvgIconsHelper
module Components::Admin::SvgIcons
  # Render an SVG icon using Phlex DSL
  # @param name [Symbol] Icon name from SvgIconsHelper::ICONS
  # @param size [String] Tailwind size (e.g., "4", "5", "8")
  # @param css_class [String] Additional CSS classes
  # @param stroke_width [String] SVG stroke width (default: "2")
  def icon(name, size: '5', css_class: '', stroke_width: '2')
    entry = SvgIconsHelper::ICONS[name.to_sym]
    unless entry
      span(class: 'text-error') { "[icon:#{name}]" }
      return
    end

    if entry.is_a?(Hash)
      path_data = entry[:path]
      fill = entry[:fill] || 'none'
      stroke = entry[:stroke] || 'currentColor'
      viewbox = entry[:viewbox] || '0 0 24 24'
      stroke_linecap = entry[:stroke_linecap] || 'round'
      stroke_linejoin = entry[:stroke_linejoin] || 'round'
      stroke_width = entry[:stroke_width] || stroke_width
      css_class = "#{css_class} #{entry[:css_class]}" if entry[:css_class].present?
    else
      path_data = entry
      fill = 'none'
      stroke = 'currentColor'
      viewbox = '0 0 24 24'
      stroke_linecap = 'round'
      stroke_linejoin = 'round'
    end

    size_class = SvgIconsHelper::SIZE_CLASSES[size.to_s] || "w-#{size} h-#{size}"
    classes = css_class.present? ? "#{size_class} #{css_class}" : size_class

    svg(
      class: classes,
      fill: fill,
      stroke: stroke,
      viewBox: viewbox
    ) do |s|
      s.path(
        stroke_linecap: stroke_linecap,
        stroke_linejoin: stroke_linejoin,
        stroke_width: stroke_width,
        d: path_data
      )
    end
  end
end
