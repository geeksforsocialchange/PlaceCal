# frozen_string_literal: true

class Views::Homepage::HousingProviders < Views::Base
  include Views::Homepage::Audiences

  def view_template
    render_audiences(exclude: :housing_providers)
  end
end
