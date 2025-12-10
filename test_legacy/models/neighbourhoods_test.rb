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

  test 'latest_release_date scope limits neighbourhoods to the latest version only' do
    Neighbourhood.delete_all

    3.times do |n|
      # neighbourhoods with current release date
      create :neighbourhood_country, name: "Country X#{n}"
    end

    5.times do |n|
      create :neighbourhood_country, name: "Country Y#{n}", release_date: DateTime.new(1990, 1)
    end

    found = Neighbourhood.latest_release.count
    assert_equal 3, found
  end

  test '::find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods' do
    Neighbourhood.delete_all

    latest_neighbourhoods =
      Array.new(5) do |n|
        # neighbourhoods with current release date
        create :neighbourhood_country, name: "Country X#{n}"
      end

    obsolete_neighbourhoods =
      Array.new(9) do |n|
        create :neighbourhood_country, name: "Country Y#{n}", release_date: DateTime.new(1990, 1)
      end

    # finds only latest neighbourhoods
    found = Neighbourhood.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(Neighbourhood, [])
    assert_equal 5, found.count

    # but can include legacy neighbourhoods that are directly referenced
    legacy_neighbourhoods = [
      obsolete_neighbourhoods[0],
      obsolete_neighbourhoods[2]
    ]

    found = Neighbourhood.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(Neighbourhood, legacy_neighbourhoods)
    assert_equal 7, found.count
  end
end
