require 'test_helper'

class SuperadminUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test 'superadmin: should get index' do
    get superadmin_users_url
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_user_url
    assert_response :success
  end

  test 'superadmin: should create user' do
    assert_difference('User.count') do
      post superadmin_users_url, params: { user: attributes_for(:user) }
    end

    assert_redirected_to superadmin_user_url(User.last)
  end

  test 'superadmin: should show user' do
    get user_url(@user)
    assert_response :success
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_user_url(@user)
    assert_response :success
  end

  test 'superadmin: should update user' do
    patch superadmin_user_url(@user), params: { user: attributes_for(:user) }
    assert_redirected_to superadmin_user_url(@user)
  end

  test 'superadmin: should destroy user' do
    assert_difference('User.count', -1) do
      delete superadmin_user_url(@user)
    end

    assert_redirected_to superadmin_root_url
  end
end
