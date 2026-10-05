# frozen_string_literal: true

class Views::Homepage::CultureTourism < Views::Homepage::Base
  def view_template
    render_audiences(exclude: :culture_tourism)
  end
end
