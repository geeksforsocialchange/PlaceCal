# frozen_string_literal: true

require 'test_helper'

class HomeIntegrationTest < ActionDispatch::IntegrationTest
  test 'home page for default site has correct title' do
    @default_site = create_default_site
    get 'http://lvh.me'
    assert_response :success
    assert_select 'title', count: 1, text: 'PlaceCal | The Community Calendar'
    # [fFf] reinstate test when new content is added to homepage
    # assert_select 'h1', count: 1, text: 'The Community Calendar'
  end

  test 'home page has correct title and metadata' do
    @site = create(:site)
    get @site.url
    assert_response :success
    assert_select 'title', count: 1, text: @site.name.to_s

    # If no better option, load the defaults
    assert_select 'h1', count: 1,
                        text: "PlaceCal is a community events calendar where you can find out everything that's happening, all in one place."
    assert_og_title @site.name.to_s
    assert_og_description "#{@site.name.to_s} is a community events calendar where you can find out everything that's happening, all in one place."

    # Images are too convoluted to test here so we are just going to test for presence for now
    assert_select 'meta[property="og:image"]', true

    # If tagline is set, then show them accordingly
    @site.update!(tagline: 'This should show up as description instead of the default description if set')
    get @site.url

    assert_og_description @site.tagline
  end
end
