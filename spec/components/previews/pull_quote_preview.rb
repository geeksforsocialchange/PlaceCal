# frozen_string_literal: true

class PullQuotePreview < Lookbook::Preview
  # @label Dark mode (default)
  def dark_mode
    render Components::PullQuote.new(
      source: "Kim Foale",
      quote_context: "Founder, PlaceCal",
      options: {}
    ) { "PlaceCal has transformed how our community finds out about local events." }
  end

  # @label Light mode
  def light_mode
    render Components::PullQuote.new(
      source: "Sarah Johnson",
      quote_context: "Community Organiser",
      options: { light_mode: true }
    ) { "Before PlaceCal, nobody knew what was going on. Now everyone does." }
  end
end
