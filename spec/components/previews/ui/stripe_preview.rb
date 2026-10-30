# frozen_string_literal: true

class UI::StripePreview < Lookbook::Preview
  # Two-tone band above a full-width map on built-in themes.
  # @label Default
  def default
    render(Components::UI::Stripe.new)
  end
end
