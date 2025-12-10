# frozen_string_literal: true

require 'test_helper'

class AdminHomeIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:root)
    @citizen = create(:citizen)
    @site_admin = create(:root)

    @site = create(:site)
    @site_admin_site = create(:site, name: 'another', site_admin: @site_admin)
  end

  test "Admin home page can't be accessed without a login" do
    @default_site = create_default_site
    get 'http://admin.lvh.me'
    assert_redirected_to 'http://admin.lvh.me/users/sign_in'
  end

  test 'Admin can access page when logged in' do
    sign_in @admin
    get 'http://admin.lvh.me'
    assert_response :success

    assert_select 'title', text: 'Dashboard | PlaceCal Admin'
  end

  test "Blank citizen gets a 'no content' warning" do
    sign_in @citizen
    get 'http://admin.lvh.me'
    assert_response :success

    assert_select 'title', text: 'Dashboard | PlaceCal Admin'
    assert_select 'h1', text: 'Missing Permissions'
  end

  test 'Dashboard shows only sites assigned to signed in admin if any are assigned' do
    sign_in(@site_admin)
    get 'http://admin.lvh.me'
    assert_response :success

    assert_select 'h5', text: @site_admin_site.name
    assert_select 'h5', text: @site.name, count: 0
  end

  test 'Dashboard shows all sites to signed in admin if none are assigned' do
    sign_in(@admin)
    get 'http://admin.lvh.me'
    assert_response :success

    assert_select 'h5', text: @site_admin_site.name
    assert_select 'h5', text: @site.name
  end
end
