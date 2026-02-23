# frozen_string_literal: true

# Render a HTML details element which is expanded at the `for-tablet-landscape-up` breakpoint
# @param header [String|nil] text to go inside a <h[1-5]/> element
# @param summary [String] text to go inside a <p/> element
# @param image_url [String|nil] optional url to an image to display
# @param header_level [Integer] optional <h[1-5]/> level. default `3`
# @param image_left [Boolean|nil] optional image position at `for-tablet-landscape-up` breakpoint. default `false`. `true` = left, `false` = right, `nil` = center. ignored if no `image_url` provided. this would be better as a param named `layout` with an enum type
# @param header_class [String|nil] optional classes to add to header element
# Usage:
# <%= render(DetailsComponent.new(header: 'Value'|nil, summary: 'Value')) do %>
#   <p>Additional markup to show when expanded</p>
# <% end %>
class DetailsComponent < ViewComponent::Base
  include SvgIconsHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(header:, summary:, image_url: nil, header_level: 3, image_left: false, header_class: nil, image_alt: nil)
    super()
    @header = header
    @summary = summary
    @image_url = image_url
    @header_level = header_level
    @image_left = image_left
    @header_class = header_class || ''
    @image_alt = image_alt || ''
  end
  # rubocop:enable Metrics/ParameterLists
end
