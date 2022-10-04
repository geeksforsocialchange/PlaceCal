# frozen_string_literal: true

require 'test_helper'

class NeighbourhoodsAncestryTest < ActiveSupport::TestCase
  setup do
    @neighbourhood = create(:neighbourhood)
    @ashton_neighbourhood = create(:ashton_neighbourhood)
    # Generated from a real postcodesio response, I just stripped out everything that was unnecessary
  end

  test 'can get parents via attribute methods' do
    assert @neighbourhood.region
    assert @neighbourhood.county
    assert @neighbourhood.district
    assert @neighbourhood.country

    assert_equal('Tameside', @ashton_neighbourhood.district.name)
    assert_equal('district', @ashton_neighbourhood.district.unit)

    assert_equal('Greater Manchester', @ashton_neighbourhood.county.name)
    assert_equal('county', @ashton_neighbourhood.county.unit)

    assert_equal('North West', @ashton_neighbourhood.region.name)
    assert_equal('region', @ashton_neighbourhood.region.unit)

    assert_equal('England', @ashton_neighbourhood.country.name)
    assert_equal('country', @ashton_neighbourhood.country.unit)
  end

  test 'uses name if name_abbr is missing' do
    # missing altogether
    hood = Neighbourhood.new(name: 'neighbourhood')
    assert_equal('neighbourhood', hood.abbreviated_name)

    # is empty string
    hood = Neighbourhood.new(name: 'neighbourhood', name_abbr: '')
    assert_equal('neighbourhood', hood.abbreviated_name)

    # is a blank string
    hood = Neighbourhood.new(name: 'neighbourhood', name_abbr: '   ')
    assert_equal('neighbourhood', hood.abbreviated_name)

    # is fine with a value
    hood = Neighbourhood.new(name: 'neighbourhood', name_abbr: 'hood')
    assert_equal('hood', hood.abbreviated_name)
  end
end
