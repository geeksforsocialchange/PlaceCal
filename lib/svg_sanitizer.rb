# frozen_string_literal: true

# Rebuilds an uploaded SVG from an allowlist of SVG elements and attributes, dropping everything else.
module SvgSanitizer
  SVG_NAMESPACE = 'http://www.w3.org/2000/svg'
  XLINK_NAMESPACE = 'http://www.w3.org/1999/xlink'

  ALLOWED_ELEMENTS = %w[
    svg g defs symbol use switch a title desc style
    path rect circle ellipse line polyline polygon image
    text tspan textPath
    linearGradient radialGradient stop pattern clipPath mask marker
    filter feBlend feColorMatrix feComponentTransfer feComposite feConvolveMatrix
    feDiffuseLighting feDisplacementMap feDistantLight feDropShadow feFlood
    feFuncA feFuncB feFuncG feFuncR feGaussianBlur feImage feMerge feMergeNode
    feMorphology feOffset fePointLight feSpecularLighting feSpotLight feTile feTurbulence
  ].to_set.freeze

  ALLOWED_ATTRIBUTES = %w[
    id class style transform viewBox preserveAspectRatio version width height
    x y x1 y1 x2 y2 cx cy r rx ry fx fy fr d points pathLength dx dy rotate
    fill fill-opacity fill-rule stroke stroke-width stroke-linecap stroke-linejoin
    stroke-miterlimit stroke-dasharray stroke-dashoffset stroke-opacity opacity color
    display visibility overflow clip-path clip-rule clipPathUnits mask maskUnits
    maskContentUnits filter filterUnits primitiveUnits gradientUnits gradientTransform
    spreadMethod offset stop-color stop-opacity patternUnits patternContentUnits
    patternTransform markerWidth markerHeight markerUnits refX refY orient
    marker-start marker-mid marker-end font-family font-size font-weight font-style
    font-variant font-stretch text-anchor dominant-baseline alignment-baseline
    baseline-shift letter-spacing word-spacing text-decoration writing-mode
    textLength lengthAdjust startOffset shape-rendering image-rendering
    text-rendering color-interpolation color-interpolation-filters mix-blend-mode
    isolation vector-effect paint-order enable-background in in2 result
    stdDeviation mode type values operator k1 k2 k3 k4 flood-color flood-opacity
    lighting-color radius tableValues slope intercept amplitude exponent
    baseFrequency numOctaves seed stitchTiles scale xChannelSelector
    yChannelSelector order kernelMatrix divisor bias targetX targetY edgeMode
    preserveAlpha surfaceScale specularConstant specularExponent diffuseConstant
    azimuth elevation z pointsAtX pointsAtY pointsAtZ limitingConeAngle
    role aria-label aria-hidden focusable
  ].to_set.freeze

  SAFE_HREF = %r{\A(?:#[\w.:-]+|data:image/(?:png|jpeg|gif|webp);base64,[A-Za-z0-9+/=\s]+)\z}

  # Stops CSS and presentation attributes loading anything external; a backslash could hide that behind a CSS escape.
  UNSAFE_CSS = /@import|expression\s*\(|javascript:|\\|url\s*\(\s*['"]?(?!#)/i
  CSS_COMMENT = %r{/\*.*?\*/}m

  # Returns nil unless the content is a well-formed SVG with something left to draw.
  def self.sanitize(svg_content)
    source = Nokogiri::XML(svg_content) { |config| config.strict.nonet }.root
    return unless source&.name == 'svg' && svg_namespace?(source, nil)

    doc = Nokogiri::XML::Document.new
    root = doc.create_element('svg')
    root.add_namespace_definition(nil, SVG_NAMESPACE)
    doc.root = root
    copy_attributes(source, root)
    copy_children(source, root, source.namespace&.href)
    return if root.element_children.empty?

    root.to_xml(encoding: 'UTF-8', save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
  rescue Nokogiri::XML::SyntaxError
    nil
  end

  def self.copy_children(source, target, root_namespace)
    source.children.each do |child|
      if child.text? || child.cdata?
        target.add_child(target.document.create_text_node(child.content))
      elsif child.element? && ALLOWED_ELEMENTS.include?(child.name) && svg_namespace?(child, root_namespace)
        next if child.name == 'style' && unsafe_css?(child.content)

        element = target.document.create_element(child.name)
        target.add_child(element)
        copy_attributes(child, element)
        copy_children(child, element, root_namespace)
      end
    end
  end

  def self.copy_attributes(source, target)
    source.attribute_nodes.each do |attr|
      namespace = attr.namespace&.href

      if attr.name == 'href' && [nil, XLINK_NAMESPACE].include?(namespace)
        target['href'] = attr.value if attr.value.strip.match?(SAFE_HREF)
      elsif namespace.nil? && ALLOWED_ATTRIBUTES.include?(attr.name) && !unsafe_css?(attr.value)
        target[attr.name] = attr.value
      end
    end
  end

  # An SVG pasted from HTML often has no xmlns, and then its children count as SVG too.
  def self.svg_namespace?(node, root_namespace)
    href = node.namespace&.href
    href == SVG_NAMESPACE || (href.nil? && root_namespace.nil?)
  end

  def self.unsafe_css?(css)
    css.gsub(CSS_COMMENT, '').match?(UNSAFE_CSS)
  end

  private_class_method :copy_children, :copy_attributes, :svg_namespace?, :unsafe_css?
end
