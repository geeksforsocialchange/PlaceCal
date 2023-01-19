# frozen_string_literal: true

require 'test_helper'

class Admin::CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    VCR.use_cassette(:collections_controller_test, record: :new_episodes, allow_playback_repeats: true) do
      @collection = create(:collection)
    end

    @root = create(:root)
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Collection Index
  #
  #   Show every Collection for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_collections_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_collections_url
    assert_redirected_to admin_root_url
  end

  # New & Create Collection
  #
  #   Allow roots to create new Collections
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[root]) do
    get new_admin_collection_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Collection.count') do
      post admin_collections_url,
           params: { collection: attributes_for(:collection) }
    end
  end

  # Edit & Update Collection
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_collection_url(@collection)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_collection_url(@collection),
          params: { collection: attributes_for(:collection) }
    # Redirect to main partner screen
    assert_response :success
  end

  # Delete Collection
  #
  #   Allow roots to delete all Collections
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Collection.count', -1) do
      delete admin_collection_url(@collection)
    end

    assert_redirected_to admin_collections_url
  end

  it_denies_access_to_destroy_for(%i[citizen]) do
    assert_no_difference('Calendar.count') do
      delete admin_collection_url(@collection)
    end

    assert_redirected_to admin_root_url
  end
end
