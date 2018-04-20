require 'test_helper'

class SuperadminCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = create(:collection)
  end

  test 'superadmin: should get index' do
    get superadmin_collections_url
    assert_response :success
  end

  test 'superadmin: should get new' do
    get new_superadmin_collection_url
    assert_response :success
  end

  test 'superadmin: should create collection' do
    assert_difference('Collection.count') do
      post superadmin_collections_url,
           params: { collection: attributes_for(:collection) }
    end

    assert_redirected_to superadmin_collection_url(Collection.last)
  end

  test 'superadmin: should show collection' do
    get superadmin_collection_url(@collection)
    assert_response :success
  end

  test 'superadmin: should get edit' do
    get edit_superadmin_collection_url(@collection)
    assert_response :success
  end

  test 'superadmin: should update collection' do
    patch superadmin_collection_url(@collection),
          params: { collection: attributes_for(:collection) }
    assert_redirected_to superadmin_collection_url(@collection)
  end

  test 'superadmin: should destroy collection' do
    assert_difference('Collection.count', -1) do
      delete superadmin_collection_url(@collection)
    end

    assert_redirected_to superadmin_collections_url
  end
end
