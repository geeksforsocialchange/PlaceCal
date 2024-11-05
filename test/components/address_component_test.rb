# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class AddressComponentTest < ViewComponent::TestCase
  setup do
    @address = '123 Moss Ln E'
    @raw_location = 'Unformatted Address, Ungeolocated Lane, Manchester'
  end

  def test_component_renders_address
    render_inline AddressComponent.new(address: @address, raw_location: @raw_location)
    assert_text 'Unformatted Address, Ungeolocated Lane, Manchester'
  end
end
