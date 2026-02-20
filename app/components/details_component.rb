# frozen_string_literal: true

# Render a HTML details element which is expanded at the `for-tablet-landscape-up` breakpoint
# @param header [String|nil] text to go inside a <h[1-5]/> element
# @param summary [String] text to go inside a <p/> element
# @param image_url [String|nil] optional url to an image to display
# @param header_level [Integer] optional <h[1-5]/> level. default `3`
# @param image_left [Boolean] optional image position at `for-tablet-landscape-up` breakpoint. default `false`. ignored if no `image_url` provided
# Usage:
# <%= render(DetailsComponent.new(header: 'Value'|nil, summary: 'Value')) do %>
#   <p>Additional markup to show when expanded</p>
# <% end %>
class DetailsComponent < ViewComponent::Base
  include SvgIconsHelper

  def initialize(header:, summary:, image_url: nil, header_level: 3, image_left: false)
    super()
    @header = header
    @summary = summary
    @image_url = image_url
    @header_level = header_level
    @image_left = image_left
  end
end
