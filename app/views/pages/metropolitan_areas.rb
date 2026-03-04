# frozen_string_literal: true

class Views::Pages::MetropolitanAreas < Views::Base
  include Views::Pages::Audiences

  def view_template
    render_audiences(exclude: :metropolitan_areas)
  end
end
