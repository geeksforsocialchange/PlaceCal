# frozen_string_literal: true

class Views::Homepage::Vcses < Views::Base
  include Views::Homepage::Audiences

  def view_template
    render_audiences(exclude: :vcses)
  end
end
