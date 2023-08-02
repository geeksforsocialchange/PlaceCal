# frozen_string_literal: true

require 'test_helper'

class NeighbourhoodFilterTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)

    address_a = create(:ashton_address)
    address_b = create(:moss_side_address)
    address_with_parent = create(:address)

    @partner_with_address_a = create(:partner, address: address_a)
    @partner_with_address_b = create(:partner, address: address_b)

    @partner_with_service_a = create(:partner, address: address_b)
    @partner_with_service_b = create(:partner, address: address_b)
    @partner_with_service_a.service_area_neighbourhoods << address_a.neighbourhood
    @partner_with_service_b.service_area_neighbourhoods << address_b.neighbourhood

    @partner_with_address_with_parent = create(:partner, address: address_with_parent)

    @filter = NeighbourhoodFilter.new(@site, [address_a.neighbourhood], { neighbourhood: address_a.neighbourhood.id })
    parent_filter = NeighbourhoodFilter.new(@site, [], { neighbourhood: address_with_parent.neighbourhood.parent.id })

    @filtered_neighbourhoods = @filter.apply_to_partner(Partner.all)
    @parent_filtered_neighbourhoods = parent_filter.apply_to_partner(Partner.all)
  end

  test '#neighbourhoods - some' do
    found = @filter.neighbourhoods
    assert_equal(1, found.length)
  end

  test '#apply_to filters partners with neighbourhoods' do
    assert_includes(@filtered_neighbourhoods, @partner_with_address_a)
    assert_not_includes(@filtered_neighbourhoods, @partner_with_address_b)
  end

  test '#apply_to filters partners in service area neighbourhoods' do
    assert_includes(@filtered_neighbourhoods, @partner_with_service_a)
    assert_not_includes(@filtered_neighbourhoods, @partner_with_service_b)
  end

  test '#apply_to filters partners with neighbourhoods that are children of current neighbourhood' do
    assert_includes(@parent_filtered_neighbourhoods, @partner_with_address_with_parent)
  end
end
