# frozen_string_literal: true

class Views::Homepage::HousingProviders < Views::Homepage::Base
  def view_template
    render_audiences(exclude: :housing_providers)
  end
end
