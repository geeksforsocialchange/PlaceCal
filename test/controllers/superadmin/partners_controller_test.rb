require 'test_helper'

class SuperadminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
  end

  test 'superadmin: should get index' do
    get superadmin_partners_url
    assert_response :success
  end

  test 'superadmin: should show partner' do
    get superadmin_partner_url(@partner)
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_superadmin_partner_url
    assert_response :success
  end

  test 'superadmin: should create partner' do
    assert_difference('Partner.count') do
      post superadmin_partners_url,
           params: { partner: { name: 'Test' } }
    end

    assert_redirected_to superadmin_partner_url(Partner.last)
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_partner_url(@partner)
    assert_response :success
  end

  test 'superadmin: should update partner' do
    patch superadmin_partner_url(@partner),
          params: { partner: { name: 'Partner Name' } }
    assert_redirected_to superadmin_partner_url(@partner)
  end

  test 'superadmin: should destroy partner' do
    assert_difference('Partner.count', -1) do
      delete superadmin_partner_url(@partner)
    end

    assert_redirected_to superadmin_partners_url
  end
end
