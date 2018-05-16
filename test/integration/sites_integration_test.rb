require 'test_helper'

class SitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @site = create(:site, slug: 'hulme')
  end

  test 'load different pages based on subdomain' do
    # Default: get home page
    get 'http://lvh.me'
    assert_template 'pages/home'
    # If there's no site, also get home
    get 'http://no-site-set.lvh.me'
    assert_template 'pages/home'
    # If there's a match, display a custom homepage
    get 'http://hulme.lvh.me'
    assert_template 'sites/hulme.html.erb'
  end
end
