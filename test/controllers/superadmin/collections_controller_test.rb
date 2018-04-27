require 'test_helper'

class SuperadminCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @collection = create(:collection)
    @root = create(:root)
  end

  it_allows_root_to_access('get', :index) do
    get superadmin_collections_url
  end

  it_denies_access_to_non_root('get', :index) do
    get superadmin_collections_url
  end

  test 'superadmin: should get index' do
    sign_in @root
    get superadmin_collections_url
    assert_response :success
  end

  it_allows_root_to_access('get', :new) do
    get new_superadmin_collection_url
  end

  it_denies_access_to_non_root('get', :new) do
    get new_superadmin_collection_url
  end

  test 'superadmin: should get new' do
    sign_in @root
    get new_superadmin_collection_url
    assert_response :success
  end

  test 'superadmin: should create collection' do
    sign_in @root
    assert_difference('Collection.count') do
      post superadmin_collections_url,
           params: { collection: attributes_for(:collection) }
    end

    assert_redirected_to superadmin_collection_url(Collection.last)
  end

  test 'superadmin: should show collection' do
    sign_in @root
    get superadmin_collection_url(@collection)
    assert_response :success
  end

  test 'superadmin: should get edit' do
    sign_in @root
    get edit_superadmin_collection_url(@collection)
    assert_response :success
  end

  test 'superadmin: should update collection' do
    sign_in @root
    patch superadmin_collection_url(@collection),
          params: { collection: attributes_for(:collection) }
    assert_redirected_to superadmin_collection_url(@collection)
  end

  test 'superadmin: should destroy collection' do
    sign_in @root
    assert_difference('Collection.count', -1) do
      delete superadmin_collection_url(@collection)
    end

    assert_redirected_to superadmin_collections_url
  end
end
