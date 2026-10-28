# frozen_string_literal: true

class Sites::PullQuotePreview < Lookbook::Preview
  def default
    render Components::Sites::PullQuote.new(
      source: "Kim Foale",
      quote_context: "Founder, PlaceCal"
    ) { "PlaceCal has transformed how our community finds out about local events." }
  end
end
