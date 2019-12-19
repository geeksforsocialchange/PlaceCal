# frozen_string_literal: true

require 'test_helper'

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tag = create(:tag)
    @root = create(:root)
    @tag_admin = create(:tag_admin)
    @tag_admin.tags << @tag
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Tag Index
  #
  #   Show every Tag for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root tag_admin]) do
    get admin_tags_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_tags_url
    assert_redirected_to admin_root_url
  end

  # New & Create Tag
  #
  #   Allow roots to create new Tags
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[root]) do
    get new_admin_tag_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Tag.count') do
      post admin_tags_url,
           params: { tag: attributes_for(:tag) }
    end
  end

  it_denies_access_to_new_for(%i[citizen]) do
    get new_admin_tag_url
    assert_redirected_to admin_root_url
  end

  # Edit & Update Tag
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_tag_url(@tag)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_tag_url(@tag),
          params: { tag: attributes_for(:tag) }
    # Redirect to main partner screen
    assert_redirected_to admin_tags_url
  end

  it_denies_access_to_edit_for(%i[citizen]) do
    get edit_admin_tag_url(@tag)
    assert_redirected_to admin_root_url
  end

  # Delete Tag
  #
  #   Allow roots to delete all Tags
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Tag.count', -1) do
      delete admin_tag_url(@tag)
    end

    assert_redirected_to admin_tags_url
  end
end
