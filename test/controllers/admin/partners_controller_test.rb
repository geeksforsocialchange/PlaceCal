require 'test_helper'

class AdminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    @turf = create(:turf)
    @turf.partners << @partner

    @root = create(:root)
    @turf_admin = create(:turf_admin)
    @turf_admin.turfs << @turf
    @partner_admin  = create(:partner_admin)
    @partner_admin.partners << @partner

    host! 'admin.lvh.me'
  end

  # Partner Index
  it_allows_access_to(%i[root turf_admin partner_admin], :index) do
    get admin_partners_url
  end

  # New Partner
  it_allows_access_to(%i[root turf_admin], :new) do
    get new_admin_partner_url
  end

  # Create Partner
  it_allows_access_to(%i[root turf_admin], :create) do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
  end

  # Delete Partner
  it_allows_access_to(%i[root turf_admin], :delete) do
    assert_difference('Partner.count', -1) do
      delete admin_partner_url(@partner)
    end

    assert_redirected_to admin_partners_url
  end

  # Edit Partner
  it_allows_access_to(%i[root turf_admin partner_admin], :edit) do
    get edit_admin_partner_url(@partner)
  end

  # Update Partner
  it_allows_access_to(%i[root turf_admin partner_admin], :patch) do
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_partners_url
  end

end
