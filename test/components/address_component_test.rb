# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class AddressComponentTest < ViewComponent::TestCase
  setup do
    # TODO: once we can make the event factory use a local calendar
    # instead of one that makes outgoing HTTP calls, switch to using
    # the event factory here. Or remove this TODO once
    # we have an integration test
    @address = create(:address)
    @raw_location = 'Unformatted Address, Ungeolocated Lane, Manchester'
  end

  def test_component_renders_address
    render_inline(AddressComponent.new(address: @address, raw_location: @raw_location))
    assert_text '123 Moss Ln E, Manchester, Manchester, M15 5DD'
  end
end
