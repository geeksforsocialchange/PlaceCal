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
        ['W1W      5AA', 'W1W 5AA'],
        ['EC1M 6HA', 'EC1M 6HA']
      ]

      table.each do |try_data, expected_output|
        address = Address.create(
          street_address: '123 street',
          postcode: try_data,
          country_code: 'gb'
        )
        address.valid?
        # the address will be invalid but we are
        # just checking if this field is formatted properly
        assert_equal address.postcode, expected_output
      end
    end
  end

  test 'address must resolve to a neighbourhood before save' do
    address = Address.new(
      street_address: 'The Resonance Centre',
      street_address2: '',
      street_address3: '',
      city: 'Manchester',
      postcode: 'M11 4UA'
    )

    assert_not address.valid?
    postcode_error = address.errors[:postcode]&.first
    assert_equal 'was not found', postcode_error

    # weird postcode.io response we don't know about
    address.postcode = 'X11 Y00'
    assert_not address.valid?
    postcode_error = address.errors[:postcode]&.first
    assert_equal 'could not be mapped to a neighbourhood', postcode_error
  end

  test 'resolves postcode on save (validation)' do
    address = Address.new(
      street_address: 'Manchester Teaching',
      street_address2: '',
      street_address3: '',
      city: 'Manchester',
      postcode: 'M16 7BA'
    )

    assert_predicate address, :valid?
    assert_predicate address.neighbourhood, :present?
  end
end
