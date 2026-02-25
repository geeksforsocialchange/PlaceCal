# frozen_string_literal: true

# Render a collapsible HTML details element which is expanded at the `for-tablet-landscape-up` breakpoint
# @param header [String|nil] text to go inside a <h[1-5]/> element
# @param summary [String] either plain text to go inside a <p/> element, or html_safe markup broken into <p/> elements
# @param header_class [String|nil] optional classes to add to header element
# @param header_level [Integer] optional <h[1-5]/> level. default `3`
# @param image_url [String|nil] optional url to an image to display
# @param image_alt [String|nil] optional image alt text
# @param image_layout ['left'|'center|'right'] optional image position at `for-tablet-landscape-up` breakpoint. default `right`. ignored if no `image_url` provided
# Usage:
# <%= render(DetailsComponent.new(header: 'Value'|nil, summary: 'Value')) do %>
#   <p>Additional markup to show when expanded</p>
# <% end %>
# add class `details-summary-collapsible` for any details added to `summary` for layout purposes
class DetailsComponent < ViewComponent::Base
  include SvgIconsHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(
    header:,
    summary:,
    header_class: nil,
    header_level: 3,
    image_url: nil,
    image_alt: nil,
    image_layout: 'right'
  )
    super()
    @header = header
    @summary = summary
    @header_class = header_class || ''
    @header_level = header_level
    @image_url = image_url
    @image_alt = image_alt || ''
    # ensure layout is valid
    @image_layout = if image_url
                      if %w[left center right].include? image_layout
                        image_layout
                      else
                        'right'
                      end
                    else
                      'none'
                    end
  end
  # rubocop:enable Metrics/ParameterLists
end
