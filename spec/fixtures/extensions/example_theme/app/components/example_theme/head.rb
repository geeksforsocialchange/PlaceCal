# frozen_string_literal: true

# Fixture head component: what a theme pushes into <head> (its stylesheet,
# fonts, manifest link). WP 0.3 gives the layout a theme head hook that
# renders this in <head>; until then the fixture view renders it inline,
# which is enough to prove the component autoloads and the asset resolves.
class ExampleTheme::Components::Head < Components::Base
  include Phlex::Rails::Helpers::AssetPath

  def view_template
    link(rel: "stylesheet", href: asset_path("example_theme/theme.css"), "data-example-theme": "head")
  end
end
