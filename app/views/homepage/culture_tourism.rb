# frozen_string_literal: true

class Views::Homepage::CultureTourism < Views::Base
  include Views::Homepage::Audiences

  def view_template
    render_audiences(exclude: :culture_tourism)
  end
end
