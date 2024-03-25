# frozen_string_literal: true

require 'test_helper'

class PartnerSiteScopeTest < ActiveSupport::TestCase
  # this verifies that partner#for_site is behaving

  # NOTE: these MUST match up with the geocoder response
  #   defined in test/support/geocoder.rb
  POST_CODE = 'M15 5DD'
  UNIT = 'ward'
  UNIT_CODE = 'E05011368' # from codes/admin_ward
  UNIT_NAME = 'Hulme' # from admin_ward
  UNIT_CODE_KEY = 'WD19CD'
  RELEASE_DATE = DateTime.new(2023, 7)

  def site
    @site ||= create(:site)
  end

  def geocodable_neighbourhood_one
    @geocodable_neighbourhood_one ||= create(
      :bare_neighbourhood,
      unit: UNIT,
      unit_name: UNIT_NAME,
      unit_code_key: UNIT_CODE_KEY,
      unit_code_value: UNIT_CODE,
      release_date: RELEASE_DATE
    )
  end

  def address_one
    @addresss_one ||= create(
      :bare_address_1,
      postcode: POST_CODE # IMPORTANT!
    )
  end

  setup do
    Neighbourhood.destroy_all
  end

  test 'empty site returns nothing' do
    output = Partner.for_site(site)
    assert_empty output, 'site should be empty'
  end

  test 'can find partners in site with address' do
    neighbourhood = geocodable_neighbourhood_one
    site.neighbourhoods << neighbourhood

    create_list :partner, 5, address: address_one

    output = Partner.for_site(site)
    assert_equal 5, output.count # number of partners with addresses in site
  end

  test 'can find partners in site with service areas (without duplicates)' do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_b

    # partners with multiple service areas in same site
    5.times do
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_a
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.save!
    end

    output = Partner.for_site(site)
    assert_equal 5, output.count
  end

  test 'can find partners by address and service_area' do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = geocodable_neighbourhood_one
    site.neighbourhoods << neighbourhood_b

    # partner by service area
    partner = build(:partner, address: nil)
    partner.service_area_neighbourhoods << neighbourhood_b
    partner.save!

    # partner by address
    create :partner, address: address_one

    output = Partner.for_site(site)
    assert_equal 2, output.count
  end

  test 'ignores partners on other sites' do
    neighbourhood_a = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_a

    neighbourhood_b = create(:bare_neighbourhood)
    site.neighbourhoods << neighbourhood_b

    neighbourhood_c = create(:bare_neighbourhood)

    # our site
    3.times do
      # scope should find these
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_a
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.save!
    end

    # other site
    other_site = create(:site)
    other_site.neighbourhoods << neighbourhood_b
    other_site.neighbourhoods << neighbourhood_c

    7.times do
      # scope should find these (because of neighbourhood_b)
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_b
      partner.service_area_neighbourhoods << neighbourhood_c
      partner.save!
    end

    2.times do
      # scope should ignore these
      partner = build(:partner, address: nil)
      partner.service_area_neighbourhoods << neighbourhood_c
      partner.save!
    end

    # finds set (neighbourhood_a OR neighbourhood_b)
    output = Partner.for_site(site)
    assert_equal 10, output.count
  end

  test 'only finds partners with tags if site has tags' do
    neighbourhood = geocodable_neighbourhood_one
    tag = create(:partnership)
    other_tag = create(:partnership)

    site.neighbourhoods << neighbourhood
    site.partnership << tag
    site.partnership << other_tag

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
