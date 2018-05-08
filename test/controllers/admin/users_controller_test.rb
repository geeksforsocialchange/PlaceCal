require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest

  setup do
    @root = create(:root)
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # User Index
  #
  #   Show every User for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_users_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_users_url
    assert_redirected_to admin_root_url
  end

  # TODO: allow admins to create users
  #
  # New & Create User
  #
  #   Allow roots to create new Users
  #   Everyone else, redirect to admin_root_url
  #
  # it_allows_access_to_new_for(%i[root]) do
  #   get new_admin_user_url
  #   assert_response :success
  # end
  #
  # it_denies_access_to_new_for(%i[citizen]) do
  #   get new_admin_user_url
  #   assert_redirected_to admin_root_url
  # end
  #
  # it_allows_access_to_create_for(%i[root]) do
  #   assert_difference('User.count') do
  #     post admin_users_url,
  #       params: { user: attributes_for(:user) }
  #   end
  # end

  # Edit & Update User
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_user_url(@citizen)
    assert_response :success
  end

  it_denies_access_to_edit_for(%i[citizen]) do
    get edit_admin_user_url(@citizen)
    assert_redirected_to admin_root_url
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_user_url(@citizen),
      params: { user: attributes_for(:user) }
    # Redirect to main partner screen
    assert_redirected_to admin_root_url
  end


  # Delete User
  #
  #   Allow roots to delete all Users
  #   Everyone else, redirect to admin_root_url

  # it_allows_access_to_destroy_for(%i[root]) do
  #   assert_difference('User.count', -1) do
  #     delete admin_user_url(@citizen)
  #   end

  #   assert_redirected_to admin_users_url
  # end


end
