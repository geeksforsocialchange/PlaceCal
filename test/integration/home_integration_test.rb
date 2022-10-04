# frozen_string_literal: true

require 'test_helper'

class HomeIntegrationTest < ActionDispatch::IntegrationTest
  test 'home page for default site has correct title' do
    @default_site = create_default_site
    get 'http://lvh.me'
    assert_response :success
    assert_select 'title', count: 1, text: 'PlaceCal | The Community Calendar'
    assert_select 'h1', count: 1, text: 'The Community Calendar'
  end

  test 'home page for neighbourhood site has correct title' do
    @neighbourhood_site = create(:site_local)
    get "http://#{@neighbourhood_site.slug}.lvh.me"
    assert_response :success
    assert_select 'title', count: 1, text: @neighbourhood_site.name.to_s
    assert_select 'h1', count: 1,
                        text: 'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
  end
end
