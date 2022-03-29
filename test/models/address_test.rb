# frozen_string_literal: true

require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  test 'normalizes postcode' do
    Geocoder.stub :search, [] do

      address = Address.create(
        street_address: '123 street',
        postcode: '   ha8 5ha ',
        country_code: 'gb'
      )
      address.save!

      assert address.postcode == 'HA8 5HA'
    end
  end
end
