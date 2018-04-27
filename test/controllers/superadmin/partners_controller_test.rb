require 'test_helper'

class SuperadminPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = create(:partner)
    @root = create(:root)
  end

  it_allows_root_to_access('get', :index) do
    get superadmin_partners_url
  end

  it_denies_access_to_non_root('get', :index) do
    get superadmin_partners_url
  end

  test 'superadmin: should get index' do
    sign_in @root
    get superadmin_partners_url
    assert_response :success
  end

  test 'superadmin: should show partner' do
    sign_in @root
    get superadmin_partner_url(@partner)
    assert_response :success
  end

  it_allows_root_to_access('get', :new) do
    get new_superadmin_event_url
  end

  it_denies_access_to_non_root('get', :new) do
    get new_superadmin_event_url
  end

  test 'superadmin: should get new' do
    sign_in @root
    get new_superadmin_partner_url
    assert_response :success
  end

  test 'superadmin: should create partner' do
    sign_in @root
    assert_difference('Partner.count') do
      post superadmin_partners_url,
           params: { partner: { name: 'Test' } }
    end

    assert_redirected_to superadmin_partner_url(Partner.last)
  end

  test 'superadmin: should get edit' do
    sign_in @root
    get edit_superadmin_partner_url(@partner)
    assert_response :success
  end

  test 'superadmin: should update partner' do
    sign_in @root
    patch superadmin_partner_url(@partner),
          params: { partner: { name: 'Partner Name' } }
    assert_redirected_to superadmin_partner_url(@partner)
  end

  test 'superadmin: should destroy partner' do
    sign_in @root
    assert_difference('Partner.count', -1) do
      delete superadmin_partner_url(@partner)
    end

    assert_redirected_to superadmin_partners_url
  end
end
