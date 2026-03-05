# frozen_string_literal: true

class Views::Pages::CultureTourism < Views::Base
  include Views::Pages::Audiences

  def view_template
    render_audiences(exclude: :culture_tourism)
  end
end
