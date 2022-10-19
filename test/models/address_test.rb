# frozen_string_literal: true

require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  test 'normalizes postcode' do
    Geocoder.stub :search, [] do
      table = [
        ['   w1w 5aa', 'W1W 5AA'],
        ['ng12 4fz  ', 'NG12 4FZ'],
        ['  ha8  8ha ', 'HA8 8HA'],
        ['W1W5AA', 'W1W 5AA'],
        ['W1W      5AA', 'W1W 5AA']
      ]

      table.each do |try_data, expected_output|
        address = Address.create(
          street_address: '123 street',
          postcode: try_data,
          country_code: 'gb'
        )
        address.save!

        assert_equal address.postcode, expected_output
      end
    end
  end
end
