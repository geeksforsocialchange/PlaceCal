# frozen_string_literal: true

class AddressComponent < ViewComponent::Base
  attr_reader :address
  attr_reader :raw_location

  def initialize(address: nil, raw_location: nil)
    @address = address
    @raw_location = raw_location
  end
  
  def formatted_address
    if address.present?

      address_lines = address.all_address_lines.map(&:strip)
      return address_lines.join(', <br>').html_safe
    end

    raw_location
  end
end
