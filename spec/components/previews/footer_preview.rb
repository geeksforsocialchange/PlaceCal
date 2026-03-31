# frozen_string_literal: true

class FooterPreview < Lookbook::Preview
  # @label Default (no site)
  # @notes Renders the generic PlaceCal footer without site-specific content.
  def default
    render Components::Footer.new(nil)
  end
end
