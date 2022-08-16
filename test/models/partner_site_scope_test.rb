# frozen_string_literal: true

require 'test_helper'

class PartnerSiteScopeTest < ActiveSupport::TestCase

  # this verifies that partner#for_site is behaving

  setup do
    neighbourhood = neighbourhoods(:one)

    @site = create(:site)
    @site.neighbourhoods << neighbourhood

    assert @site.neighbourhoods.length == 1

    address_partner_1 = build(:partner, address: create(:address, neighbourhood: neighbourhood))
    address_partner_1.save!

    address_partner_2 = build(:partner, address: create(:address, neighbourhood: neighbourhood))
    address_partner_2.save!

    service_area_partner_1 = build(:partner, address: nil)
    service_area_partner_1.service_areas.build(neighbourhood: neighbourhood)
    service_area_partner_1.save!

    service_area_partner_2 = build(:partner, address: nil)
    service_area_partner_2.service_areas.build(neighbourhood: neighbourhood)
    service_area_partner_2.save!

    service_area_partner_3 = build(:partner, address: nil)
    service_area_partner_3.service_areas.build(neighbourhood: neighbourhood)
    service_area_partner_3.save!

    # has both, should appear only once though
    address_and_service_area_partner = build(:partner, address: nil)
    address_and_service_area_partner.address = create(:address, neighbourhood: neighbourhood)
    address_and_service_area_partner.service_areas.build(neighbourhood: neighbourhood)
    address_and_service_area_partner.save!
  end

  test "can find partners in site with address" do
    output = Partner.for_site(@site)
    count = output.count
    assert count == 6 # number of partners with addresses in site
  end

  test "works with sites that have multiple neighbourhoods" do
    other_neighbourhood = neighbourhoods(:two)
    @site.neighbourhoods << other_neighbourhood

    address_partner_3 = build(:partner, address: create(:address, neighbourhood: other_neighbourhood))
    address_partner_3.save!

    service_area_partner_4 = build(:partner, address: nil)
    service_area_partner_4.service_areas.build(neighbourhood: other_neighbourhood)
    service_area_partner_4.save!

    output = Partner.for_site(@site)
    count = output.count
    assert count == 8 # number of partners with addresses in site
  end

  # being very thorough and paranoid about my SQL fu -IK
  test "it definitely works even when there's a second site" do

    other_site = create(:site)
    other_neighbourhood = neighbourhoods(:moss_side)
    other_site.neighbourhoods << other_neighbourhood

    address_partner_4 = build(:partner, address: create(:moss_side_address, neighbourhood: other_neighbourhood))
    address_partner_4.save!

    service_area_partner_5 = build(:partner, address: nil)
    service_area_partner_5.service_areas.build(neighbourhood: other_neighbourhood)
    service_area_partner_5.save!

    output = Partner.for_site(other_site)
    count = output.count
    assert count == 2 # only two partners in other site
  end

  test "it returns distinct partners that don't repeat" do
    # even if there are multiple paths from site to partner

    site = create(:site)

    neighbourhood = create(:neighbourhood_country, name: 'Alpha')
    site.neighbourhoods << neighbourhood

    other_neighbourhood = create(:neighbourhood_country, name: 'Beta')
    site.neighbourhoods << other_neighbourhood

    tag = create(:tag)
    site.tags << tag

    other_tag = create(:tag)
    site.tags << other_tag

    # by address
    partner_address = create(:bare_address_1, neighbourhood: neighbourhood)
    partner = create(:partner, address: partner_address)

    # by service area
    partner.service_area_neighbourhoods << other_neighbourhood
    partner.service_area_neighbourhoods << neighbourhood

    # by tag
    partner.tags << tag
    partner.tags << other_tag

    found = Partner.for_site(site)
    assert_equal 1, found.count, 'Partner should only appear once'

    first = Partner.for_site(site).first
    assert_equal partner.name, first.name
  end
end

