# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class AddressComponentTest < ViewComponent::TestCase
  setup do
    VCR.use_cassette('import_test_calendar') do
      @test_event = create(:event)
      @address = @test_event.address.street_address
      @raw_location = @test_event.raw_location_from_source
    end
  end

  def test_component_renders_address
    render_inline AddressComponent.new(address: @address, raw_location: @raw_location)
    assert_text 'Unformatted Address, Ungeolocated Lane, Manchester'
  end
end
