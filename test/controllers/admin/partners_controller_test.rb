require 'test_helper'

class Admin::PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    @turf = @partner.turfs.first

    @root = create(:root)
    @citizen = create(:user)

    @turf_admin = create(:turf_admin)
    @turf_admin.turfs << @turf

    @partner_admin  = create(:partner_admin)
    @partner_admin.partners << @partner

    host! 'admin.lvh.me'
  end

  # Partner Index
  #
  #   Show every Partner for roots
  #   Show an empty page for citizens
  #   TODO: Allow turf_admins and partner_admins to view their Partners

  it_allows_access_to_index_for(%i[root turf_admin]) do
    get admin_partners_url
    assert_response :success
    # Has a button allowing us to add new Partners
    assert_select "a", "Add New Partner"
    # Returns one entry in the table
    assert_select 'tbody tr', 1
  end

  it_allows_access_to_index_for(%i[partner_admin citizen]) do
    get admin_partners_url
    assert_response :success
    # Nothing to show in the table
    assert_select 'tbody tr', 0
  end

  # New & Create Partner
  #
  #   Allow roots to create new Partners
  #   Everyone else, redirect to admin_partners_url
  #   TODO: Allow turf_admins to create new Partners

  it_allows_access_to_new_for(%i[root turf_admin]) do
    get new_admin_partner_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root turf_admin]) do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
  end


  # Edit & Update Partner
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_partners_url
  #   TODO: allow turf_admins and partner_admins to edit their Partners

  it_allows_access_to_edit_for(%i[root turf_admin partner_admin]) do
    get edit_admin_partner_url(@partner)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root turf_admin partner_admin]) do
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_partners_url
  end

  # Delete Partner
  #
  #   Allow roots to delete all Partners
  #   Everyone else redirect to admin_partners_url
  #   TODO: Allow turf_admin and partner_admins to delete Partners

  it_allows_access_to_destroy_for(%i[root turf_admin]) do
    assert_difference('Partner.count', -1) do
      delete admin_partner_url(@partner)
    end

   assert_redirected_to admin_partners_url
  end

end
