# frozen_string_literal: true

# Sanitizes SVG content by removing script tags, event handlers, and other
# potentially dangerous elements/attributes that could enable XSS attacks.
#
# Uses Nokogiri (already a Rails dependency) for XML parsing.
module SvgSanitizer
  # Elements that can execute code or load external resources
  DANGEROUS_ELEMENTS = %w[
    script
    foreignObject
    set
    use
  ].freeze

  # Values that indicate JavaScript execution
  DANGEROUS_VALUE_PATTERN = /\A\s*javascript:/i

  def self.sanitize(svg_content)
    doc = Nokogiri::XML(svg_content)

    # Remove dangerous elements
    DANGEROUS_ELEMENTS.each do |element|
      doc.css(element).each(&:remove)
    end

    # Remove dangerous attributes from all elements
    doc.traverse do |node|
      next unless node.element?

      node.attributes.each do |name, attr|
        # Remove event handlers (onclick, onload, onerror, etc.)
        if name.start_with?('on')
          attr.remove
          next
        end

        # Remove javascript: values from any attribute
        attr.remove if attr.value.match?(DANGEROUS_VALUE_PATTERN)
      end
    end

    doc.to_xml
  end
end
