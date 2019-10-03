# frozen_string_literal: true

require 'test_helper'

class HomeIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @default_site = create_default_site
    @neighbourhood_site = create(:site_local)
  end

  test 'home page for default site has correct title' do
    get root_url
    assert_response :success
    assert_select 'title', count: 1, text: "PlaceCal | The Community Calendar"
    assert_select 'h1', count: 1, text: 'Welcome to PlaceCal'
  end

  test 'home page for neighbourhood site has correct title' do
    get "http://#{@neighbourhood_site.slug}.lvh.me"
    assert_response :success
    assert_select 'title', count: 1, text: "#{@neighbourhood_site.name} | The Community Calendar"
    assert_select 'h1', count: 1, text: 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
  end
end
