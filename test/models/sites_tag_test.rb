# frozen_string_literal: true

require "test_helper"

class SitesNeighbourhoodTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
    @neighbourhood = create(:neighbourhood)
  end

  test "can only make one association for each pair" do
    sn = SitesNeighbourhood.new(site: @site, neighbourhood: @neighbourhood)
    sn2 = sn.dup
    assert sn.save
    assert_not sn2.save
  end
end
