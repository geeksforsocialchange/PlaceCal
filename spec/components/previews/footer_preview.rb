# frozen_string_literal: true

# @display padding false
class FooterPreview < Lookbook::Preview
  # @label Default (no site)
  # @notes Renders the generic PlaceCal footer without site-specific content.
  def default
    render Components::Sites::Footer.new(nil)
  end
end
