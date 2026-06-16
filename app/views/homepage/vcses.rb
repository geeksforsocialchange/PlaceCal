# frozen_string_literal: true

class Views::Homepage::Vcses < Views::Homepage::Base
  def view_template
    render_audiences(exclude: :vcses)
  end
end
