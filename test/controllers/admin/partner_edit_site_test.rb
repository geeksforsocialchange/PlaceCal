# frozen_string_literal: true

require 'test_helper'

class PartnerEditSiteTest < ActionDispatch::IntegrationTest
  setup do
    Neighbourhood.destroy_all

    # tied to neighbourhood through postcode -> geocoder -> neighbourhood
    @neighbourhood = create(
      :bare_neighbourhood,
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011368',
      unit_name: 'Hulme',
      name: 'Hulme'
    )
    assert_predicate @neighbourhood, :valid?

    @address = create(:bare_address_1, postcode: 'M15 5DD')
    assert_predicate @address, :valid?
    assert_equal @address.neighbourhood, @neighbourhood

    # warning: this partner is invalid and is not saved
    @partner = build(:partner, service_area_neighbourhoods: [], address: nil)
    @site = create(:site)
    @root_user = create(:root)

    sign_in @root_user
  end

  test 'user can see sites this partner is involved with via addresses' do
    @partner.address = @address
    @partner.save!

    @site.neighbourhoods << @address.neighbourhood

    get edit_admin_partner_url(@partner)

    assert_select 'span#partner-sites a', count: 1
    assert_select 'span#partner-sites a:first', text: @site.name
  end

  test 'user can see sites this partner is involved with via service areas' do
    @partner.service_area_neighbourhoods << @neighbourhood
    @partner.save!

    @site.neighbourhoods << @neighbourhood

    get edit_admin_partner_url(@partner)

    assert_select 'span#partner-sites a', count: 1
    assert_select 'span#partner-sites a:first', text: @site.name
  end

  # service area selector

  test 'root users can see all neighbourhoods' do
    @partner.service_area_neighbourhoods << @neighbourhood
    @partner.save!

    given_lots_of_neighbourhoods_exist

    get edit_admin_partner_url(@partner)

    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 10
  end

  # partner owner can see all neighbourhoods
  test 'partner owner can see all neighbourhoods' do
    @partner.service_area_neighbourhoods << @neighbourhood
    @partner.save!

    given_lots_of_neighbourhoods_exist

    other_user = create(:user)
    assert_not other_user.neighbourhood_admin?

    other_user.partners << @partner # owns this

    sign_in other_user
    get edit_admin_partner_url(@partner)

    # has same number as root
    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 10
  end

  # user can only see neighbourhoods they admin
  test 'non root user can only see neighbourhoods they have assigned' do
    @partner.service_area_neighbourhoods << @neighbourhood
    @partner.address = @address
    @partner.save!

    other_user = create(:user)

    given_lots_of_neighbourhoods_exist

    # giver user some neighbourhoods
    4.times do |i|
      hood = create(
        :bare_neighbourhood,
        unit: 'name',
        unit_code_key: 'key',
        unit_code_value: '123456789',
        unit_name: 'name',
        name: "Neighbourhood #{i}"
      )
      assert_predicate hood, :valid?
      other_user.neighbourhoods << hood
    end

    other_user.neighbourhoods << @partner.address.neighbourhood
    assert_predicate other_user, :neighbourhood_admin?

    sign_in other_user
    get edit_admin_partner_url(@partner)

    # can only see the neighbourhoods the user owns
    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 5
  end

  def given_lots_of_neighbourhoods_exist
    9.times do |i|
      create(
        :bare_neighbourhood,
        unit: 'name',
        unit_code_key: 'key',
        unit_code_value: '123456789',
        unit_name: 'name',
        name: "Neighbourhood #{i}"
      )
    end
  end
end
