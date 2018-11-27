# frozen_string_literal: true

require 'test_helper'

class CollectionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
    @collection = create(:collection)
  end

  test 'should show title based' do
    get partner_url(@partner)
    assert_select 'h1', @partner.name
  end
end
