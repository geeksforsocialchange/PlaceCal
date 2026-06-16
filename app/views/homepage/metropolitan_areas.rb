# frozen_string_literal: true

class Views::Homepage::MetropolitanAreas < Views::Homepage::Base
  def view_template
    render_audiences(exclude: :metropolitan_areas)
  end
end
