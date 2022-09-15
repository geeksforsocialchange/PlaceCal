# frozen_string_literal: true

# rubocop:disable Style/StringLiterals

require 'test_helper'

class AdminUserIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @default_site = create_default_site
    @partner = create(:partner)
    @neighbourhood = create(:neighbourhood)

    @root = create(:root)
    @root.partners << @partner
    @root.neighbourhoods << @neighbourhood

    @neighbourhood_admin = create(:user)
    @neighbourhood_admin.neighbourhoods << @neighbourhood

    @partner_admin = create(:user)
    @partner_admin.partners << @partner

    @citizen = create(:user)
    get "http://admin.lvh.me"
  end

  test "User admin index has appropriate title" do
    sign_in(@root)
    get admin_users_path
    assert_response :success

    assert_select 'title', text: "Users | PlaceCal Admin"
    assert_select 'h1', text: "Users"
  end


  test "root : can get new user" do
    sign_in @root

    get new_admin_user_path

    assert_select 'title', text: "New User | PlaceCal Admin"
  end

  test "Profile form has correct fields for root" do
    sign_in @root
    get admin_profile_path
    assert_response :success

    assert_select 'h1', text: "Edit Profile"

    assert_select 'h2', text: 'Basic information'
    assert_select 'label', text: 'First name'
    assert_select 'label', text: 'Last name'
    assert_select 'label', text: 'Email *'
    assert_select 'label', text: 'Phone'
    assert_select 'label', text: 'Avatar'

    assert_select 'h2', text: 'Password'
    assert_select 'label', text: 'Password'
    assert_select 'label', text: 'Password confirmation'
    assert_select 'label', text: 'Current password'

    assert_select 'h2', text: 'Admin rights'
    assert_select 'div.profile__is-root'
    assert_select 'h3', text: 'Your partners'
    assert_select 'a[href=?]',
                  edit_admin_partner_path(@partner),
                  text: @partner.name
    assert_select 'h3', text: 'Your neighbourhoods'
    assert_select 'a[href=?]',
                  edit_admin_neighbourhood_path(@neighbourhood),
                  text: @neighbourhood.contextual_name
  end

  test "Profile form has correct fields for neighbourhood admin" do
    sign_in @neighbourhood_admin
    get admin_profile_path
    assert_response :success

    assert_select 'h3', text: 'Your neighbourhoods', count: 1
    assert_select 'h3', text: 'Your partners', count: 0
  end

  test "Profile form has correct fields for partner admin" do
    sign_in @partner_admin
    get admin_profile_path
    assert_response :success

    assert_select 'h3', text: 'Your neighbourhoods', count: 0
    assert_select 'h3', text: 'Your partners', count: 1
  end

  test "Create form has correct fields for root" do
    sign_in @root
    get new_admin_user_path(@citizen)
    assert_response :success

    assert_select 'h1', 'New User'
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'h3', 'Partners'
    assert_select 'h3', 'Neighbourhoods'
    assert_select 'h3', 'Allowed Tags'
    assert_select 'h3', 'Role'
  end

  test "Create form has correct fields for neighbourhood admin" do
    sign_in @neighbourhood_admin
    get new_admin_user_path(@citizen)
    assert_response :success

    assert_select 'input[type="hidden"][name="_method"][value="put"]', count: 0
    assert_select 'h1', 'New User'
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'h3', 'Partners'
    assert_select 'h3', 'Allowed Tags'
    assert_select 'h3', 'Neighbourhoods', count: 0
    assert_select 'h3', 'Role', count: 0
  end


  test "Edit form has correct fields for root" do
    sign_in @root
    get edit_admin_user_path(@citizen)
    assert_response :success

    assert_select 'input[type="hidden"][name="_method"][value="put"]', count: 1
    assert_select 'h1', "Edit User: #{@citizen.full_name}"
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'h3', 'Partners'
    assert_select 'h3', 'Neighbourhoods'
    assert_select 'h3', 'Allowed Tags'
    assert_select 'h3', 'Role'
  end

  test "Edit form has correct fields for neighbourhood admin" do
    sign_in @neighbourhood_admin
    get edit_admin_user_path(@citizen)
    assert_response :success

    assert_select 'h1', "Edit User: #{@citizen.full_name}"
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'h3', 'Partners'
    assert_select 'h3', 'Neighbourhoods', count: 0
    assert_select 'h3', 'Allowed Tags'
    assert_select 'h3', 'Role', count: 0
  end

  test "shows partner select list" do
    sign_in @root

    5.times do |i|
      FactoryBot.create(:partner, users: [@root])
    end

    get new_admin_user_path
    assert_response :success

    assert_select 'select#user_partner_ids option', count: 6
  end

  test "new user has preselected partner when ID provided" do
    sign_in @root
    5.times do |i|
      FactoryBot.create(:partner, users: [@root])
    end

    get new_admin_user_path(partner_id: @partner.id)
    assert_response :success

    assert_select 'select#user_partner_ids option[selected="selected"]', @partner.name
  end

  test "root users can edit neighbourhoods" do
    @root.neighbourhoods.destroy_all

    @root.neighbourhoods << neighbourhoods(:one)
    @root.neighbourhoods << neighbourhoods(:two)

    sign_in @root
    get edit_admin_user_path(@root)

    assert_response :success

    # selector box with two pre-selected values
    assert_select "select#user_neighbourhood_ids option[@selected='selected']", count: 2

    # cannot see the neighbourhood list
    assert_select "ul.neighbourhood-list", count: 0
  end

  test "citizen neighbourhood_admins users can see a list of their neighbourhoods" do
    @citizen.neighbourhoods.destroy_all

    @citizen.neighbourhoods << neighbourhoods(:one)
    @citizen.neighbourhoods << neighbourhoods(:two)

    sign_in @citizen
    get edit_admin_user_path(@citizen)

    assert_response :success

    # selector box is not visible
    assert_select "select#user_neighbourhood_ids", count: 0

    # neighbourhood list has two entries
    assert_select "ul.neighbourhood-list li", count: 2
  end

  test "citizens with no rights get a warning message on their profile" do
    @citizen.neighbourhoods.destroy_all
    @citizen.tags.destroy_all
    @citizen.partners.destroy_all

    sign_in @citizen
    get admin_profile_path(@citizen)
    assert_response :success

    assert_select "p.has-no-admin-rights-warning"
  end

  test 'new user avatar upload problem feedback' do
    sign_in @root

    new_user_params = {
      email: 'user@example.com',
      role: 'root',
      avatar: fixture_file_upload("bad-cat-picture.bmp"),
    }

    post admin_users_path, params: { user: new_user_params }
    assert_not response.redirect?

    assert_select "h6", text: "1 error prohibited this User from being saved"

    # top of page form error box
    assert_select '#form-errors li', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"

    assert_select 'form .user_avatar .invalid-feedback', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"
  end

  test 'update user avatar upload problem feedback' do
    sign_in @root

    user_params = {
      email: @root.email,
      role: @root.role,
      avatar: fixture_file_upload("bad-cat-picture.bmp"),
    }

    put admin_user_path(@root), params: { user: user_params }
    assert_not response.redirect?

    assert_select "h6", text: "1 error prohibited this User from being saved"

    # top of page form error box
    assert_select '#form-errors li', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"

    assert_select 'form .user_avatar .invalid-feedback', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"
  end

  test 'update profile avatar upload problem feedback' do
    sign_in @root

    user_params = {
      email: @root.email,
      avatar: fixture_file_upload("bad-cat-picture.bmp"),
    }

    patch update_profile_admin_user_path(@root), params: { user: user_params }
    assert_not response.redirect?

    assert_select "h6", text: "1 error prohibited this User from being saved"

    # top of page form error box
    assert_select '#form-errors li', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"

    assert_select 'form .user_avatar .invalid-feedback', text: "Avatar You are not allowed to upload \"bmp\" files, allowed types: jpg, jpeg, png"
  end

end
