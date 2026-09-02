# frozen_string_literal: true

module ExampleTheme
  class Engine < ::Rails::Engine
    # Not isolate_namespace: an extension plugs into the host app's routes,
    # helpers and layout rather than living behind a mount point.

    # Phlex views live under app/views/<extension>/ and components under
    # app/components/<extension>/. Rails does not autoload app/views, and it
    # autoloads app/components under the top-level namespace, so the engine
    # pushes its own directories with explicit namespaces. This mirrors what
    # core does in config/initializers/phlex.rb for Views and Components,
    # but stays entirely inside the engine.
    initializer "example_theme.phlex_namespaces", before: :set_autoload_paths do
      Rails.autoloaders.main.push_dir(
        root.join("app/views/example_theme"),
        namespace: ExampleTheme::Views
      )
      Rails.autoloaders.main.push_dir(
        root.join("app/components/example_theme"),
        namespace: ExampleTheme::Components
      )
    end

    # Register the theme (D1). Runs before core's config/initializers, which
    # is why core requires the registry from config/application.rb.
    initializer "example_theme.register_theme" do
      PlaceCal::Extensions.register_theme(:example_theme) do |theme|
        theme.stylesheet "example_theme/theme"
        theme.homepage_view "ExampleTheme::Views::Home"
        theme.head "ExampleTheme::Components::Head"
        theme.event_filter_style :day_strip
      end
    end
  end
end
