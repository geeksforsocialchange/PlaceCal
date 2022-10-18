# frozen_string_literal: true

require 'test_helper'

class PartnerSiteWithTagScopeTest < ActiveSupport::TestCase
  # this verifies that partner#for_site is behaving

  # NOTE: these MUST match up with the geocoder response
  #   defined in test/support/geocoder.rb
  POST_CODE = 'M15 5DD'
  UNIT = 'ward'
  UNIT_CODE = 'E05011368' # from codes/admin_ward
  UNIT_NAME = 'Hulme' # from admin_ward
  UNIT_CODE_KEY = 'WD19CD'

  def site
    @site ||= create(:site)
  end

  def geocodable_neighbourhood_one
    @geocodable_neighbourhood_one ||= create(
      :bare_neighbourhood,
      unit: UNIT,
      unit_name: UNIT_NAME,
      unit_code_key: UNIT_CODE_KEY,
      unit_code_value: UNIT_CODE
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

  test 'empty site/tag returns nothing' do
    tag = nil
    output = Partner.for_site_with_tag(site, tag)
    assert_empty output, 'site should be empty'
  end

  test 'finds partners with tag' do
    tag = create(:tag)
    other_tag = create(:tag)

    neighbourhood = geocodable_neighbourhood_one
    site.neighbourhoods << neighbourhood
    site.tags << tag
    site.tags << other_tag

    4.times do |n|
      partner = create(:partner, name: "Partner #{n}", address: address_one)
      partner.tags << tag
    end

    6.times do |n|
      partner = create(:partner, name: "Partner without tag #{n}", address: address_one)
      partner.tags << other_tag
    end

    2.times do |n|
      create :partner, name: "Partner with no tags #{n}", address: address_one
    end

    output = Partner.for_site_with_tag(site, tag)
    assert_equal 4, output.all.length
  end
end
