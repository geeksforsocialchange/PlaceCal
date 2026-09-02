# frozen_string_literal: true

# Core's built-in themes, registered through the same registry that
# extensions use (#3368, D1). The registry itself is required from
# config/application.rb so that extension engines, whose initializers run
# before this file, can register into it.
#
# Each built-in stylesheet is app/assets/stylesheets/themes/<name>.scss,
# built by dartsass (config/initializers/dartsass.rb), with a matching
# public/map-styles/<name>.json.
%w[pink orange green blue].each do |name|
  PlaceCal::Extensions.register_theme(name, core: true) do |theme|
    theme.stylesheet "themes/#{name}"
    theme.map_style name
  end
end

# Legacy per-site theme: the stylesheet and map style are looked up by the
# site's slug (themes/custom/<slug>.css, public/map-styles/<slug>.json).
# Only Mossley uses it. Kept so existing sites work untouched; new bespoke
# sites should be extensions instead.
PlaceCal::Extensions.register_theme(:custom, core: true) do |theme|
  theme.stylesheet do |site|
    path = "themes/custom/#{site.slug}"
    # The per-site asset may not exist in the pipeline (#2936): link nothing
    # rather than raise Propshaft::MissingAssetError.
    path if Rails.application.assets&.resolver&.resolve("#{path}.css").present?
  end
  theme.map_style(&:slug)
end
