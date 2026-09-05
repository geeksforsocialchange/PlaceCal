# frozen_string_literal: true

module ExampleTheme
  class Engine < ::Rails::Engine
    # Not isolate_namespace: an extension plugs into the host app's routes,
    # helpers and layout rather than living behind a mount point.
    #
    # PlaceCal::Extension is the shared engine infrastructure (WP 5.2 of
    # #3368): it pushes the Phlex namespaces for the app/views/example_theme
    # and app/components/example_theme directories this engine ships, runs the
    # host and theme guards, and registers the theme below. This fixture is
    # what proves it, so it uses it exactly as a real extension does.
    include PlaceCal::Extension

    # Every theme DSL setting this engine uses. The fixture exercises the whole
    # slot surface, so the list is the whole slot surface.
    required_settings %i[
      stylesheet homepage_view head footer nav_cta map_style menu_label
      event_filter_style theme_color background_color icons og_image page
    ]

    theme :example_theme do |theme|
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
                  mask_icon_color: "#FF7AA7",
                  icon_192: "example_theme/icons/icon-192.png",
                  icon_512: "example_theme/icons/icon-512.png"
      theme.og_image "example_theme/icons/og.png", width: 1200, height: 675
      theme.page "proof", "ExampleTheme::Views::Proof", nav_label_key: "example_theme.nav.proof"
    end
  end
end
