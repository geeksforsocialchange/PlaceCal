# frozen_string_literal: true

class Components::MaxWidth < Components::Base
  def view_template(&)
    div(class: 'max_width', &)
  end
end
