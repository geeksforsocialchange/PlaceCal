# frozen_string_literal: true

require 'test_helper'

class AdminHomeIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:root)
    @citizen = create(:citizen)
  end

  test "Admin home page can't be accessed without a login" do
    @default_site = create_default_site
    get "http://admin.lvh.me"
    assert_redirected_to "http://admin.lvh.me/users/sign_in"
  end

  test "Admin can access page when logged in" do
    sign_in @admin
    get "http://admin.lvh.me"
    assert_response :success

    assert_select 'title', text: "Dashboard | PlaceCal Admin"
  end

  test "Blank citizen gets a 'no content' warning" do
    sign_in @citizen
    get "http://admin.lvh.me"
    assert_response :success

    assert_select 'title', text: "Dashboard | PlaceCal Admin"
    assert_select 'h1', text: "Missing Permissions"
  end

end
