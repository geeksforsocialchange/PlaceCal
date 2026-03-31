# frozen_string_literal: true

class AddressPreview < Lookbook::Preview
  # @label With address
  def with_address
    address = Address.new(
      street_address: "Hulme Community Garden Centre",
      street_address2: "28 Old Birley Street",
      street_address3: "Hulme",
      city: "Manchester",
      postcode: "M15 5RF"
    )
    render Components::Address.new(address: address)
  end

  # @label With raw URL location
  def with_raw_url
    render Components::Address.new(raw_location: "https://zoom.us/j/123456789")
  end

  # @label With raw text location
  def with_raw_text
    render Components::Address.new(raw_location: "Meeting point: outside the library")
  end
end
