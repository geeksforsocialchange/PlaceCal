# frozen_string_literal: true

# Fixture theme footer: rendered by the layout in place of core's Footer for
# sites on this theme (theme footer slot). Receives the site and the derived
# navigation tuples.
class ExampleTheme::Components::Footer < Components::Base
  prop :site, ::Site
  prop :navigation, Array, default: -> { [] }

  def view_template
    footer(class: "example-theme-footer", "data-example-theme": "footer") do
      p { @site.name }
      ul { @navigation.each { |label, path| li { a(href: path) { label } } } }
    end
  end
end
