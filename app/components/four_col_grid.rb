# frozen_string_literal: true

class Components::FourColGrid < Components::Base
  prop :partnership_cards, _Boolean, default: false

  def view_template(&)
    ul(class: @partnership_cards ? 'four_col_grid--larger' : 'four_col_grid', &)
  end
end
