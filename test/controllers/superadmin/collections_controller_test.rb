# frozen_string_literal: true

require 'test_helper'

class SuperadminCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = create(:collection)
    @root = create(:root)
  end

  it_allows_access_to_index_for(%i[root]) do
    get superadmin_collections_url
  end

  it_allows_access_to_show_for(%i[root]) do
    get superadmin_collection_url(@collection)
  end

  it_allows_access_to_new_for(%i[root]) do
    get new_superadmin_collection_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Collection.count') do
      post superadmin_collections_url,
           params: { collection: { name: 'Test Collection' } }
    end
  end

  it_allows_access_to_update_for(%i[root]) do
    patch superadmin_collection_url(@collection),
          params: { collection: { name: 'New Test Collection Name' } }
  end

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Collection.count', -1) do
      delete superadmin_collection_url(@collection)
    end
  end
end
