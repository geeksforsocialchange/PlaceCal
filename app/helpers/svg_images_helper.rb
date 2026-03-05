# frozen_string_literal: true

# SVG Images Helper
# Wraps `inline_svg` gem
module SvgImagesHelper
  # Render an SVG image
  # @param name [String] Image name or path relative to `app/assets/images` or `uploads/` with or without '.svg' extension
  # @param alt_text [String] Mapped to <title/> inside the rendered <svg/>
  # @param css_class [String] Additional CSS classes
  # @return [String] HTML-safe SVG element
  # Usage:
  # <%= svg_image('logo-footer', alt_text: 'PlaceCal') %>
  def svg_image(name, alt_text: '', css_class: '')
    file_name = if name.match?(/\.svg$/i)
                  name
                else
                  "#{name}.svg"
                end
    # See https://www.rubydoc.info/gems/inline_svg/1.10.0
    # Use helpers proxy when available (ViewComponents), fall back to direct call (views, helper specs)
    svg_helper = respond_to?(:helpers) ? helpers : self
    svg_helper.inline_svg_tag(
      file_name,
      aria: true,
      class: css_class,
      title: alt_text
    )
  end
end
