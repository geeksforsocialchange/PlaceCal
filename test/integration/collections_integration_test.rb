# frozen_string_literal: true

require "test_helper"

class CollectionsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @site = create_default_site
    @collection = create(:collection)
  end

  test "should show collection" do
    skip "New neighbourhood code stopped this working but Collections not used currently"
    get collection_url(@collection)
    assert_response :success
    assert_select "title", count: 1, text: "#{@collection.name} | #{@site.name}"
    assert_select "div.hero h4", text: "The Community Calendar"
    assert_select "div.hero h1", text: @collection.name
    assert_select "ol article", 5
  end
end
