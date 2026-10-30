# frozen_string_literal: true

# The theme tokens a scope's rendered markup reads: through the utility classes on its parts and on the plain elements
# inside them, and through core's element styles for their tags. Nested scopes are left to their own declarations.
module ThemingTokens
  module_function

  def read_by(html, scope)
    elements(html, scope).flat_map { |element| for_element(element) }.uniq.sort
  end

  def elements(html, scope)
    html.css(%([data-scope="#{scope}"][data-part])).flat_map do |part|
      [part] + own_descendants(part, scope)
    end.uniq
  end

  def own_descendants(node, scope)
    node.element_children.flat_map do |child|
      child["data-scope"] && child["data-scope"] != scope ? [] : [child] + own_descendants(child, scope)
    end
  end

  def for_element(element)
    classes = element["class"].to_s.split
    classes.flat_map { class_tokens.fetch(it, []) } + tag_tokens.fetch(element.name, [])
  end

  def theme_tokens
    @theme_tokens ||= Rails.root.join("app/tailwind/public/_theme.css").read[/^:root \{(.*?)^\}/m, 1].scan(/(--[\w-]+):/).flatten
  end

  # From the built stylesheet, so @apply, @utility and variants are already resolved.
  def rules
    @rules ||= Rails.root.join("app/assets/builds/public_tailwind.css").read.gsub(%r{/\*.*?\*/}m, "")
                    .scan(/([^{}]+)\{([^{}]*)\}/)
                    .map { |selectors, body| [selectors.split(",").map(&:strip), body.scan(/var\((--[\w-]+)/).flatten & theme_tokens] }
  end

  def class_tokens
    @class_tokens ||= index { |selector| selector[/\A\.((?:\\.|[\w-])+)(?::[\w-]+(?:\([^)]*\))?)*\z/, 1]&.gsub(/\\(.)/, '\1') }
  end

  def tag_tokens
    @tag_tokens ||= index { |selector| selector[/\A[a-z][a-z0-9]*\z/] }
  end

  def index
    rules.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(selectors, tokens), map|
      selectors.each { |selector| (key = yield(selector)) && map[key] |= tokens }
    end
  end
end
