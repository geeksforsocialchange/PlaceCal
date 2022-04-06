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
end
