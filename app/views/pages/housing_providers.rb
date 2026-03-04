# frozen_string_literal: true

class Views::Pages::HousingProviders < Views::Base
  include Views::Pages::Audiences

  def view_template
    render_audiences(exclude: :housing_providers)
  end
end
