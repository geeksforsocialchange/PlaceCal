# frozen_string_literal: true

# Specs that render a component or call a helper outside a request have no
# ApplicationController to populate Current, so anything reading Current.theme
# sees the null theme. These set it the way the controller would.
module CurrentThemeHelpers
  # @param site [Site, nil]
  def use_current_site(site)
    Current.site = site
    Current.theme = PlaceCal::Theme.for(site)
    site
  end

  # @param theme_name [Symbol, String] a registered theme
  def use_current_theme(theme_name)
    Current.theme = PlaceCal::Extensions.fetch_theme(theme_name)
  end
end

RSpec.configure do |config|
  config.include CurrentThemeHelpers
  config.after { Current.reset }
end
