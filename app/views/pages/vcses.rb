# frozen_string_literal: true

class Views::Pages::Vcses < Views::Base
  include Views::Pages::Audiences

  def view_template
    render_audiences(exclude: :vcses)
  end
end
