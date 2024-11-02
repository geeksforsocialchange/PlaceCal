# frozen_string_literal: true

class AddressComponent < ViewComponent::Base
  def initialize(address, raw_location: nil)
    @address = address
    @raw_location = raw_location
  end

  def formatted_address
    # rubocop:disable Rails/OutputSafety
    if address.present?

      address_lines = address.all_address_lines.map(&:strip)
      return address_lines.join(', <br>').html_safe
    end

    uri = URI.parse(raw_location)
    "<a href='#{uri}'>#{uri.hostname}</a>".html_safe

  rescue URI::InvalidURIError
    raw_location
  end
  # rubocop:enable Rails/OutputSafety
end
