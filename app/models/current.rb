# frozen_string_literal: true

# Per-request attributes. `site` is the Site resolved from the request host
# (nil on the nationwide directory and the admin subdomain), set by
# ApplicationController so that view-layer helpers such as theme-scoped
# translations (PlaceCal::ThemeTranslation) can reach it without threading
# the site through every component.
class Current < ActiveSupport::CurrentAttributes
  attribute :site, :theme

  # The resolved theme for the request. Never nil: PlaceCal::Theme::NONE stands
  # in for the directory, for an unthemed site and for code running outside a
  # request, so callers read theme settings without a nil check.
  def theme
    super || PlaceCal::Theme::NONE
  end
end
