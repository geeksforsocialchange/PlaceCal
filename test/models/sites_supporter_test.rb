# frozen_string_literal: true

require "test_helper"

class SitesSupporterTest < ActiveSupport::TestCase
  setup do
    @supporter = create(:supporter)
    @site = create(:site)
  end

  test "can only make one association for each pair" do
    ss = SitesSupporter.new(supporter: @supporter, site: @site)
    ss2 = ss.dup
    assert ss.save
    assert_not ss2.save
  end
end
