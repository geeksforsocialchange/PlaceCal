# frozen_string_literal: true

# rubocop:disable Style/StringLiterals

require 'test_helper'

class AdminPUserIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:root)
    @default_site = create_default_site
    @partner = create(:partner)
    @neighbourhood = create(:neighbourhood)
    @admin.partners << @partner
    @admin.neighbourhoods << @neighbourhood
    get "http://admin.lvh.me"
    sign_in @admin
  end

  test "Edit form has correct fields" do
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
    assert_select 'h3', text: 'Your partners'
    assert_select 'a[href=?]',
                  edit_admin_partner_path(@partner),
                  text: @partner.name
    assert_select 'h3', text: 'Your neighbourhoods'
    assert_select 'a[href=?]',
                  edit_admin_neighbourhood_path(@neighbourhood),
                  text: @neighbourhood.name
  end
end
