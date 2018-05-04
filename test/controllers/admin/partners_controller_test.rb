require 'test_helper'

class AdminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
   @partner = create(:partner)
   @turf = @partner.turfs.first

   @root = create(:root)
   #TODO: Consider non-admin and non-root users
   #@user = create(:user)

   @turf_admin = create(:turf_admin)
   @turf_admin.turfs << @turf

   @partner_admin  = create(:partner_admin)
   @partner_admin.partners << @partner

    host! 'admin.lvh.me'
  end

  # Partner Index
  it_allows_access_to_index_for(%i[root turf_admin partner_admin]) do
    get admin_partners_url
    assert_response :success
  end

  # New Partner
  it_allows_access_to_new_for(%i[root turf_admin]) do
    get new_admin_partner_url
    assert_response :success
  end

  # Create Partner
  it_allows_access_to_create_for(%i[root turf_admin]) do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
  end

  # Edit Partner
  it_allows_access_to_edit_for(%i[root turf_admin partner_admin]) do
    get edit_admin_partner_url(@partner)
    assert_response :success
  end


  # Update Partner
  it_allows_access_to_update_for(%i[root turf_admin partner_admin]) do
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_partners_url
  end

  # Delete Partner
  #it_allows_access_to_destroy_for(%i[root turf_admin]) do
  #  assert_difference('Partner.count', -1) do
  #    delete admin_partner_url(@partner)
  #  end

  #  assert_redirected_to admin_partners_url
  #end

end
