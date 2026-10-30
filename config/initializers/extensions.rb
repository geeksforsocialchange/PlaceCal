# frozen_string_literal: true

# Core's built-in themes, registered through the same registry that
# extensions use (#3368, D1). The registry itself is required from
# config/application.rb so that extension engines, whose initializers run
# before this file, can register into it.
#
# Each built-in theme's colours are in app/tailwind/public/_themes.css, picked
# by data-theme on <html>, with a matching public/map-styles/<name>.json.
# theme_color is read from each theme's --color-primary there.
primary_colors = Rails.root.join('app/tailwind/public/_themes.css').read
                      .scan(/html\[data-theme="(\w+)"\]\s*\{[^}]*?--color-primary:\s*(#\h{6})/).to_h

%w[pink orange green blue].each do |name|
  PlaceCal::Extensions.register_theme(name, core: true) do |theme|
    theme.map_style name
    theme.theme_color primary_colors.fetch(name)
  end
end
