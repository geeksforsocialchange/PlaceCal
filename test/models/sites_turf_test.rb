# frozen_string_literal: true

require 'test_helper'

class SitesTurfTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
    @turf = create(:turf)
  end

  test 'can only make one association for each pair' do
    st = SitesTurf.new(site: @site, turf: @turf)
    st2 = st.dup
    assert st.save
    assert_not st2.save
  end
end
