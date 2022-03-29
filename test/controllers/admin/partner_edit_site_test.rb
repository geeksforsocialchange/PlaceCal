# frozen_string_literal: true

require 'test_helper'

class PartnerEditSiteTest < ActionDispatch::IntegrationTest
  setup do
    @root_user = create(:root)
    sign_in @root_user
    
    @site = build(:site)
    @site.save!

    @partner = build(:partner)
    @partner.save!
  end

  test 'user can see sites this partner is involved with' do
    @site.neighbourhoods << @partner.address.neighbourhood
    get edit_admin_partner_url(@partner)

    assert_select 'ul#partner-sites li', count: 1
    assert_select 'ul#partner-sites li:first a', text: @site.name
  end
end

