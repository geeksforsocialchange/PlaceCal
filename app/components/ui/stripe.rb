# frozen_string_literal: true

# The two-tone band built-in themes draw across the page above a full-width map.
class Components::UI::Stripe < Components::Base
  def view_template
    div(class: 'border-t-10 border-map-stripe-second shadow-map-stripe', aria_hidden: 'true')
  end
end
