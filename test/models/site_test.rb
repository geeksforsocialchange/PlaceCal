# frozen_string_literal: true

require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
  end

  test "gets correct stylesheet link" do
    assert_equal 'themes/pink', @site.stylesheet_link
    @site.theme = :custom
    @site.slug = 'my-town'
    assert_equal 'themes/custom/my-town', @site.stylesheet_link
    @site.slug = 'default-site'
    assert_equal false, @site.stylesheet_link
  end
end
