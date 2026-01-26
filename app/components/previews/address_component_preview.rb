# frozen_string_literal: true

class AddressComponentPreview < ViewComponent::Preview
  # @label With Address Object
  def with_address
    address = OpenStruct.new(
      all_address_lines: ['123 High Street', 'Manchester', 'M1 2AB']
    )
    render(AddressComponent.new(address: address))
  end

  # @label With URL Location
  def with_url_location
    render(AddressComponent.new(address: nil, raw_location: 'https://zoom.us/j/123456789'))
  end

  # @label With Plain Text Location
  def with_plain_text_location
    render(AddressComponent.new(address: nil, raw_location: 'Online via Microsoft Teams'))
  end
end
