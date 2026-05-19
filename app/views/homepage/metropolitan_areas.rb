# frozen_string_literal: true

class Views::Homepage::MetropolitanAreas < Views::Base
  include Views::Homepage::Audiences

  def view_template
    render_audiences(exclude: :metropolitan_areas)
  end
end
