# frozen_string_literal: true

# Fixture head component: what a theme pushes into <head> (its stylesheet,
# fonts, manifest link). The core layout renders this for any site whose
# theme registers a head component (#3368 D1/D3), so it only appears on
# pages served for an example_theme site.
class ExampleTheme::Components::Head < Components::Base
  include Phlex::Rails::Helpers::AssetPath

  def view_template
    link(rel: "stylesheet", href: asset_path("example_theme/theme.css"), "data-example-theme": "head")
  end
end
