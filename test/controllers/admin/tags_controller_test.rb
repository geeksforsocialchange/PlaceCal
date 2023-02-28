# frozen_string_literal: true

require 'test_helper'

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @tag_admin = create(:tag_admin)
    @partner_admin = create(:partner_admin)
    @citizen = create(:user)

    @unassigned_root_tag = create(:tag)
    @assigned_root_tag = @tag_admin.tags.first

    host! 'admin.lvh.me'
  end

  # Tag Index
  #
  #   Show every Tag for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root tag_admin partner_admin]) do
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

  it_denies_access_to_new_for(%i[tag_admin partner_admin citizen]) do
    get new_admin_tag_url
    assert_redirected_to admin_root_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Tag.count') do
      post admin_tags_url,
           params: { tag: attributes_for(:tag) }
    end
  end

  it_denies_access_to_create_for(%i[tag_admin partner_admin citizen]) do
    assert_no_difference('Tag.count') do
      post admin_tags_url,
           params: { tag: attributes_for(:tag) }
    end
  end

  # Edit & Update Tag
  #
  #   Allow roots to update all tags
  #   Allow partner admins to only update partner_ids of public tags (if they are only a partner admin,
  #                                                                   they have been assigned no tags)
  #   Allow tag admins to update partner_ids of public tags, and root-assigned tags
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root partner_admin tag_admin]) do
    get edit_admin_tag_url(@unassigned_root_tag)
    assert_response :success
  end

  it_denies_access_to_edit_for(%i[citizen]) do
    get edit_admin_tag_url(@unassigned_root_tag)
    assert_redirected_to admin_root_url
  end

  # Delete Tag
  #
  #   Allow roots to delete all Tags
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Tag.count', -1) do
      delete admin_tag_url(@unassigned_root_tag)
    end

    assert_redirected_to admin_tags_url
  end

  it_denies_access_to_destroy_for(%i[tag_admin partner_admin citizen]) do
    assert_no_difference('Tag.count') do
      delete admin_tag_url(@unassigned_root_tag)
    end

    assert_redirected_to admin_root_url
  end
end
