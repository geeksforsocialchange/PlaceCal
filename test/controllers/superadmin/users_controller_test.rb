require 'test_helper'

class SuperadminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @root = create(:root)
  end

  it_allows_root_to_access('get', :index) do
    get superadmin_users_url
  end

  it_denies_access_to_non_root('get', :index) do
    get superadmin_users_url
  end

  test 'superadmin: should get index' do
    sign_in @root
    get superadmin_users_url
    assert_response :success
  end

  it_allows_root_to_access('get', :new) do
    get new_superadmin_user_url
  end

  it_denies_access_to_non_root('get', :new) do
    get new_superadmin_user_url
  end

  test 'superadmin: should get new' do
    sign_in @root
    get new_user_url
    assert_response :success
  end

  test 'superadmin: should create user' do
    sign_in @root
    assert_difference('User.count') do
      post superadmin_users_url, params: { user: attributes_for(:user, email: 'test@test.com') }
    end

    assert_redirected_to superadmin_user_url(User.last)
  end

  test 'superadmin: should show user' do
    sign_in @root
    get user_url(@user)
    assert_response :success
  end

  test 'superadmin: should get edit' do
    sign_in @root
    get edit_superadmin_user_url(@user)
    assert_response :success
  end

  test 'superadmin: should update user' do
    sign_in @root
    patch superadmin_user_url(@user), params: { user: attributes_for(:user) }
    assert_redirected_to superadmin_user_url(@user)
  end

  test 'superadmin: should destroy user' do
    sign_in @root
    assert_difference('User.count', -1) do
      delete superadmin_user_url(@user)
    end

    assert_redirected_to superadmin_root_url
  end
end
