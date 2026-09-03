# frozen_string_literal: true

# Per-request attributes. `site` is the Site resolved from the request host
# (nil on the nationwide directory and the admin subdomain), set by
# ApplicationController so that view-layer helpers such as theme-scoped
# translations (PlaceCal::ThemeTranslation) can reach it without threading
# the site through every component.
class Current < ActiveSupport::CurrentAttributes
  attribute :site
end
