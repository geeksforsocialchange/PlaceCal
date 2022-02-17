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
    assert_select 'label', /\APartners/
    assert_select 'label', /\ANeighbourhoods/
    assert_select 'label', 'Role *'
    assert_select 'label', 'Facebook app'
    assert_select 'label', 'Facebook app secret'
  end

  test "Create form has correct fields for neighbourhood admin" do
    sign_in @neighbourhood_admin
    get new_admin_user_path(@citizen)
    assert_response :success

    assert_select 'h1', 'New User'
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'label', /\APartners/
    assert_select 'label', html: /\A'Neighbourhoods/, count: 0
    assert_select 'label', text: 'Role *', count: 0
    assert_select 'label', text: 'Facebook app', count: 0
    assert_select 'label', text: 'Facebook app secret', count: 0
  end


  test "Edit form has correct fields for root" do
    sign_in @root
    get edit_admin_user_path(@citizen)
    assert_response :success

    assert_select 'h1', "Edit User: #{@citizen.full_name}"
    assert_select 'label', 'First name'
    assert_select 'label', 'Last name'
    assert_select 'label', 'Email *'
    assert_select 'label', 'Phone'
    assert_select 'label', 'Avatar'
    assert_select 'label', /\APartners/
    assert_select 'label', /\ANeighbourhoods/
    assert_select 'label', 'Role *'
    assert_select 'label', 'Facebook app'
    assert_select 'label', 'Facebook app secret'
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
    assert_select 'label', /\APartners/
    assert_select 'label', html: /\A'Neighbourhoods/, count: 0
    assert_select 'label', text: 'Role *', count: 0
    assert_select 'label', text: 'Facebook app', count: 0
    assert_select 'label', text: 'Facebook app secret', count: 0
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
end
