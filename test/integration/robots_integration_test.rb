# frozen_string_literal: true

require 'test_helper'

class RobotsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @published_site = create(:site, is_published: true)
    @unpublished_site = create(:site, is_published: false)
  end

  test 'robots.txt blocks site if site is unpublished' do
    get "http://#{@unpublished_site.slug}.lvh.me:3000/robots.txt"
    assert_response 200
    assert_equal forbid_string, response.body
  end

  test 'robots.txt has default comment if site is published' do
    get "http://#{@published_site.slug}.lvh.me:3000/robots.txt"
    assert_response 200
    assert_equal '# See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file', response.body
  end

  private

  def forbid_string
    <<~TXT
      # See http://www.robotstxt.org/robotstxt.html for documentation on how to use the robots.txt file
      User-agent: *
      Disallow: /
    TXT
  end
end
