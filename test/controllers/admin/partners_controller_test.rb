require 'test_helper'

class AdminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    sign_in create(:user)
  end

  test 'admin: should get index' do
    get admin_partners_url
    assert_response :success
  end

  test 'admin: should show partner' do
    # puts admin_partner_url(@partner)
    get admin_partner_url(@partner)
    assert_response :success
  end

  test 'admin: should get new' do
    get new_admin_partner_url
    assert_response :success
  end

  test 'admin: should create partner' do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: attributes_for(:partner) }
    end

    assert_redirected_to admin_partner_url(Partner.last)
  end

  test 'admin: should get edit' do
    get edit_admin_partner_url(@partner)
    assert_response :success
  end

  test 'admin: should update partner' do
    patch admin_partner_url(@partner),
          params: { partner: attributes_for(:partner) }
    assert_redirected_to admin_partner_url(@partner)
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
