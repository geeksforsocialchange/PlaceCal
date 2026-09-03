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
        theme.footer "ExampleTheme::Components::Footer"
        theme.nav_cta "example_theme.nav.donate", "https://example.org/donate"
        theme.map_style "example_theme"
        theme.menu_label true
        theme.event_filter_style :day_strip
        theme.theme_color "#ff7aa7"
        theme.background_color "#040f39"
        theme.icons favicon_32: "example_theme/icons/favicon-32x32.png",
                    favicon_16: "example_theme/icons/favicon-16x16.png",
                    apple_touch_icon: "example_theme/icons/apple-touch-icon.png",
                    mask_icon: "example_theme/icons/mask-icon.svg",
                    icon_192: "example_theme/icons/icon-192.png",
                    icon_512: "example_theme/icons/icon-512.png"
        theme.mask_icon_color "#FF7AA7"
        theme.og_image "example_theme/icons/og.png", width: 1200, height: 675
      end
    end
  end
end
