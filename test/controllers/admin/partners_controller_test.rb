require 'test_helper'

class AdminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    host! 'admin.lvh.me'
  end

  test 'admin: should get index' do
    sign_in create(:admin)
    get admin_partners_url
    assert_response :success
  end

  test "admin: non-admins can't access index" do
    sign_in create(:user)
    get admin_partners_url
    assert_redirected_to admin_root_path
  end

  # No show page as we go directly to edit for now
  #
  # test 'admin: should show partner' do
  #   get admin_partner_url(@partner)
  #   assert_response :success
  # end

  test 'admin: should get new' do
    sign_in create(:admin)
    get new_admin_partner_url
    assert_response :success
  end

  test "admin: non-admins can't access new" do
    sign_in create(:user)
    get admin_partners_url
    assert_redirected_to admin_root_path
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
