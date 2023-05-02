# frozen_string_literal: true

require 'test_helper'

class PartnerEditSiteTest < ActionDispatch::IntegrationTest
  setup do
    @root_user = create(:root)
    @partner = create(:partner, service_area_neighbourhoods: [create(:neighbourhood)])

    sign_in @root_user
  end

  test 'user can see sites this partner is involved with via addresses' do
    @site = create(:site, neighbourhoods: [@partner.address.neighbourhood])
    get edit_admin_partner_url(@partner)

    assert_select 'span#partner-sites a', count: 1
    assert_select 'span#partner-sites a:first', text: @site.name
  end

  test 'user can see sites this partner is involved with via service areas' do
    @site = create(:site, neighbourhoods: @partner.service_area_neighbourhoods)
    get edit_admin_partner_url(@partner)

    assert_select 'span#partner-sites a', count: 1
    assert_select 'span#partner-sites a:first', text: @site.name
  end

  # service area selector

  # root can see all neighbourhoods
  test 'user who is not partner admin' do
    get edit_admin_partner_url(@partner)
    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 12
  end

  # user can only see neighbourhoods they admin
  test 'non root user can only see neighbourhoods they have assigned' do
    other_user = create(:user)

    neighbourhoods = Neighbourhood.all
    3.times do |n|
      other_user.neighbourhoods << neighbourhoods[n]
    end

    other_user.neighbourhoods << @partner.address.neighbourhood
    assert_predicate other_user, :neighbourhood_admin?

    sign_in other_user
    get edit_admin_partner_url(@partner)

    # this is numbered 8 as we get all the subtree nodes of the neighbourhoods
    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 8
  end

  # if owns partner can see all neighbourhoods
  test 'partner admins can select all neighbourhoods' do
    other_user = create(:user)
    assert_not other_user.neighbourhood_admin?

    other_user.partners << @partner # owns this

    sign_in other_user
    get edit_admin_partner_url(@partner)

    # has same number as root
    assert_select '#partner_service_areas_attributes_0_neighbourhood_id option', count: 12
  end
end
