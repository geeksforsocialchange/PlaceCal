# frozen_string_literal: true

# Cleans uploaded SVGs with Loofah's safelist, the one Rails uses to sanitise HTML.
module SvgSanitizer
  SVG_NAMESPACE = 'http://www.w3.org/2000/svg'

  # Loofah's own CSS scrubber drops most SVG properties (fill: url(#...), opacity, stop-color), so CSS is only checked for external loads.
  UNSAFE_CSS = /@import|expression\s*\(|javascript:|\\|url\s*\(\s*['"]?(?!#)/i
  CSS_COMMENT = %r{/\*.*?\*/}m

  # Loofah's prune, except that <style> blocks, style attributes and embedded images survive when safe, and foreignObject never does.
  class Scrubber < Loofah::Scrubbers::Prune
    def scrub(node)
      return super unless node.element?

      case node.name
      when 'foreignObject' then node.remove
      when 'style' then scrub_style_element(node)
      when 'image' then scrub_image(node)
      else
        style = node.remove_attribute('style')&.value
        result = super
        node['style'] = style if result == CONTINUE && style && SvgSanitizer.safe_css?(style)
        return result
      end
      STOP
    end

    private

    def scrub_style_element(node)
      node.attribute_nodes.each(&:remove)
      node.remove unless node.children.all? { |child| child.text? || child.cdata? } && SvgSanitizer.safe_css?(node.content)
    end

    def scrub_image(node)
      node.children.remove
      Loofah::HTML5::Scrub.scrub_attributes(node)
    end
  end

  # Returns nil unless the content is a well-formed SVG with something left to draw.
  def self.sanitize(svg_content)
    root = Loofah::XML::Document.parse(svg_content) { |config| config.strict.nonet }.root
    return unless root&.name == 'svg' && [nil, SVG_NAMESPACE].include?(root.namespace&.href)

    root.document.scrub!(Scrubber.new)
    return if root.element_children.empty?

    # Inline SVG works without an xmlns, but a file served as an image needs one.
    root.default_namespace = SVG_NAMESPACE if root.namespace.nil?
    root.to_xml(encoding: 'UTF-8', save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  rescue Nokogiri::XML::SyntaxError
    nil
  end

  def self.safe_css?(css)
    !css.gsub(CSS_COMMENT, '').match?(UNSAFE_CSS)
  end
end
