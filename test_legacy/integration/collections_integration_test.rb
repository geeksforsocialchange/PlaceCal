# frozen_string_literal: true

require 'test_helper'

class CollectionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @site = create_default_site
    @collection = create(:collection)
  end

  test 'should show collection' do
    get collection_url(@collection)
    assert_response :success

    assert_select 'title', count: 1, text: "#{@collection.name} | #{@site.name}"
    assert_select 'div.hero h1', text: @collection.name
    # assert_select 'ol article', 5
  end
end
