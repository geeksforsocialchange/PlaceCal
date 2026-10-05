# frozen_string_literal: true

# Core's built-in themes, registered through the same registry that
# extensions use (#3368, D1). The registry itself is required from
# config/application.rb so that extension engines, whose initializers run
# before this file, can register into it.
#
# Each built-in stylesheet is app/assets/stylesheets/themes/<name>.scss,
# built by dartsass (config/initializers/dartsass.rb), with a matching
# public/map-styles/<name>.json.
# A local, not a top-level constant: nothing outside this file needs it.
theme_colors = {
  pink: '#f19089',
  orange: '#fe9263',
  green: '#afcf5a',
  blue: '#74d4ec'
}.freeze

%w[pink orange green blue].each do |name|
  PlaceCal::Extensions.register_theme(name, core: true) do |theme|
    theme.stylesheet "themes/#{name}"
    theme.map_style name
    theme.theme_color theme_colors[name.to_sym]
  end
end
