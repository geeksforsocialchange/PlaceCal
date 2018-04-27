require 'test_helper'

class AdminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    host! 'admin.lvh.me'
  end

  it_allows_admin_to_access('get', :index) do
    get admin_partners_url
  end

  it_denies_access_to_non_admin('get', :index) do
    get admin_partners_url
  end

  # No show page as we go directly to edit for now
  #
  # test 'admin: should show partner' do
  #   get admin_partner_url(@partner)
  #   assert_response :success
  # end

  it_allows_admin_to_access('get', :new) do
    get new_admin_partner_url
  end

  it_denies_access_to_non_admin('get', :new) do
    get new_admin_partner_url
  end

  test 'admin: should create partner' do
    sign_in create(:admin)
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
    # Redirect to the main partner screen
    assert_redirected_to admin_partners_url
  end

  test 'admin: should get edit' do
    sign_in create(:admin)
    get edit_admin_partner_url(@partner)
    assert_response :success
  end

  test 'admin: should update partner' do
    sign_in create(:admin)
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to admin_partners_url
  end

  # We don't let admins delete from this screen yet
  #
  # test 'admin: should destroy partner' do
  #   assert_difference('Partner.count', -1) do
  #     delete admin_partner_url(@partner)
  #   end
  #
  #   assert_redirected_to admin_partners_url
  # end
end
