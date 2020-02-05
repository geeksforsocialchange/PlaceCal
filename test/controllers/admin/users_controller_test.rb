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

  # Profile
  test "root: can access profile" do
    sign_in @root

    get admin_profile_path
    assert_response :success
  end

  test "neighbourhood_admin: can access profile" do
    sign_in @neighbourhood_admin

    get admin_profile_path
    assert_response :success
  end

  test "citizen: can access profile" do
    sign_in @citizen

    get admin_profile_path
    assert_response :success
  end

  # Update Profile
  test "user can update their profile" do
    sign_in @root

    patch update_profile_admin_user_path(@root),
          params: { user: { first_name: 'Bob' }}

    assert_redirected_to admin_root_url
    assert_equal 'Bob', @root.reload.first_name
  end

  test "user cannot update other's profile" do
    user = create(:user, first_name: 'Test')

    sign_in @root

    patch update_profile_admin_user_path(user),
          params: { user: { first_name: 'Name' }}

    assert_redirected_to admin_root_url
    assert_equal 'Test', user.reload.first_name
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

  it_allows_access_to_new_for(%i[root neighbourhood_admin]) do
    get new_admin_user_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[citizen]) do
    get new_admin_user_url
    assert_redirected_to admin_root_url
  end

  it_allows_access_to_create_for(%i[root neighbourhood_admin]) do
    assert_difference('User.count', 1) do
      post admin_users_url,
           params: { user: attributes_for(:user) }
    end
  end

  it_denies_access_to_create_for(%i[citizen]) do
    get new_admin_user_url
    assert_redirected_to admin_root_url
  end

  # Edit & Update User
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root neighbourhood_admin]) do
    get edit_admin_user_url(@citizen)
    assert_response :success
  end

  it_denies_access_to_edit_for(%i[citizen]) do
    get edit_admin_user_url(@citizen)
    assert_redirected_to admin_root_url
  end

  it_allows_access_to_update_for(%i[root neighbourhood_admin]) do
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

  test 'neighbourhood_admin : can only update partner_ids' do
    sign_in @neighbourhood_admin
    new_neighbourhood = create(:neighbourhood)

    patch admin_user_url(@citizen),
          params: { user: { first_name: 'Bob',
                            last_name: 'Smith',
                            partner_ids: [@partner.id],
                            neighbourhood_ids: [new_neighbourhood.id] } }

    assert_redirected_to admin_users_url

    @citizen.reload # Ensure updated record is fetched

    assert_not_equal 'Bob', @citizen.first_name
    assert_not_equal 'Smith', @citizen.last_name
    assert_equal [@partner.id], @citizen.partner_ids
    assert_equal [], @citizen.neighbourhood_ids
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

  it_denies_access_to_destroy_for(%i[partner_admin neighbourhood_admin citizen]) do
    assert_no_difference('User.count') do
      delete admin_user_url(@citizen)
    end

    assert_redirected_to admin_root_url
  end
end
