# frozen_string_literal: true

require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @citizen = create(:user)

    @partner_admin = create(:partner_admin)
    @partner = @partner_admin.partners.first

    host! 'admin.lvh.me'
  end

  # User Index
  #
  #   Show every User for roots
  #   Show users in the appropriate neighbourhood for secretaries
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root neighbourhood_admin]) do
    get admin_users_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_users_url
    assert_redirected_to admin_root_url
  end

  # Admins and secretaries can create users
  #
  # New & Create User
  #
  #   Allow roots to create new Users
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[neighbourhood_admin]) do
    get new_admin_user_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[citizen]) do
    get new_admin_user_url
    assert_redirected_to admin_root_url
  end

  # TODO: Work out why this is saying host isn't set when it is
  # it_allows_access_to_create_for(%i[root]) do
  #   assert_difference('User.count') do
  #     post admin_users_url,
  #          params: { user: attributes_for(:user) }
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
    # Redirect to users screen
    assert_redirected_to admin_users_url
  end

  it_denies_access_to_update_for(%i[citizen]) do
    patch admin_user_url(@citizen),
          params: { user: attributes_for(:user) }
    # Redirect to main partner screen
    assert_redirected_to admin_root_url
  end

  # Delete User
  #
  #   Allow roots to delete all Users
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('User.count', -1) do
      delete admin_user_url(@citizen)
    end

    assert_redirected_to admin_users_url
  end

  it_denies_access_to_destroy_for(%i[partner_admin citizen]) do
    assert_no_difference('User.count') do
      delete admin_user_url(@citizen)
    end

    assert_redirected_to admin_root_url
  end
end
