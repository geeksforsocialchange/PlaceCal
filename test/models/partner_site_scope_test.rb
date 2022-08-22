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

    # by address
    partner_address = create(:bare_address_1, neighbourhood: neighbourhood)
    partner = create(:partner, address: partner_address)

    # by service area
    partner.service_area_neighbourhoods << other_neighbourhood
    partner.service_area_neighbourhoods << neighbourhood

    found = Partner.for_site(site)
    assert_equal 1, found.count, 'Partner should only appear once'

    first = found.first
    assert_equal partner.name, first.name
  end

  test "only finds partners with tags if site has tags" do
    neighbourhood = create(:neighbourhood_country, name: 'Alpha')
    tag = create(:tag)
    other_tag = create(:tag)

    site = create(:site)
    site.neighbourhoods << neighbourhood
    site.tags << tag
    site.tags << other_tag

    # NOTE: we assume the relations between partners and sites via address
    #   neighbourhoods works and is tested elsewhere

    # present
    partner_a = create_partner_with_tags(neighbourhood, tag)

    # present
    partner_b = create_partner_with_tags(neighbourhood, other_tag)

    # present
    partner_c = create_partner_with_tags(neighbourhood, tag, other_tag)

    # skipped
    partner_d = create_partner_with_tags(neighbourhood)

    found = Partner.for_site(site)
    assert_equal 3, found.count, 'Partner should only appear once'

    found_ids = found.map(&:id)
    should_be_ids = [partner_a.id, partner_b.id, partner_c.id]

    assert_equal found_ids, should_be_ids
  end

  def create_partner_with_tags(neighbourhood, *tags)
    partner = build(:partner, address: nil)
    partner.service_area_neighbourhoods << neighbourhood
    tags.each do |tag|
      partner.tags << tag
    end
    partner.save!

    partner
  end
end
