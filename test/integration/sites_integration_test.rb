# frozen_string_literal: true

require 'test_helper'

class SitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
    @root = create(:root)
    @site_admin = create(:user)
    @site = create(:site, slug: 'hulme', site_admin: @site_admin)
  end

  test 'load different pages based on subdomain' do
    # Default: get home page
    get 'http://lvh.me'
    assert_template 'pages/home'
    # If there's no site, also get home
    get 'http://no-site-set.lvh.me'
    assert_redirected_to 'http://lvh.me/'
    # If there's a match, display a custom homepage
    get 'http://hulme.lvh.me'
    assert_template 'sites/default'
  end

  test 'basic page content shows up' do
    get 'http://hulme.lvh.me'
    assert_select 'h1', 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
    assert_select 'h2', "PlaceCal is working to make #{@site.place_name} a better connected neighbourhood."
    assert_select 'p', @site.description
    assert_select 'strong', @site_admin.full_name
    assert_select 'strong', @site_admin.phone
    assert_select 'strong', @site.site_admin.email
    assert_select 'h3', 'Adding Your Events'
    assert_select 'h3', 'Getting Online'
    assert_select 'h3', 'PlaceCal Support'
    assert_select 'p', 'Information about getting online coming soon.'
  end
end
