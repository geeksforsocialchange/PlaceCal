# frozen_string_literal: true

class AddressComponent < ViewComponent::Base
  erb_template <<~ERB
    <p class="place_info__address" property="address" typeof="PostalAddress">
      <%= formatted_address %>
    </p>
  ERB

  def initialize(address:, raw_location: nil)
    super
    @address = address
    @raw_location = raw_location
  end

  def formatted_address
    if @address.present?
      address_lines = @address.all_address_lines.map(&:strip)
      return address_lines.join(', <br>').html_safe # rubocop:disable Rails/OutputSafety
    end

    uri = URI.parse(raw_location)
    "<a href='#{uri}'>#{uri.hostname}</a>".sanitize

  rescue URI::InvalidURIError
    raw_location
  end
end
