# frozen_string_literal: true

require 'test_helper'

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @tag_admin = create(:tag_admin)
    @partner_admin = create(:partner_admin)
    @citizen = create(:user)

    @public_tag = create(:tag_public)
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

  # FIXME: this should be in a policy test as that is what it is testing,
  #   not the controller

  def test_update_root
    # Root can edit everything
    assert allows_access(@root, @public_tag, :update)
    # assert allows_access(@root, @unassigned_root_tag, :update)
    assert allows_access(@root, @assigned_root_tag, :update)
  end

  # FIXME: this should be in a policy test as that is what it is testing,
  #   not the controller
  def test_update_partner_admin
    # Partner admins
    # can only edit public tags
    assert allows_access(@partner_admin, @public_tag, :update)
    # assert denies_access(@partner_admin, @unassigned_root_tag, :update)
    # assert denies_access(@partner_admin, @assigned_root_tag, :update)
  end

  # FIXME: this should be in a policy test as that is what it is testing,
  #   not the controller
  # def test_update_tag_admin
  #   # Tag admins
  #   # can only edit tags that are public, or they have had assigned to them
  #   assert_includes @tag_admin.tags, @assigned_root_tag # For prosperity
  #   assert allows_access(@tag_admin, @public_tag, :update)
  #   assert allows_access(@tag_admin, @assigned_root_tag, :update)
  # end

  def test_update_citizen
    # Citizens may do nothing :)
    assert denies_access(@citizen, @public_tag, :update)
    assert denies_access(@citizen, @unassigned_root_tag, :update)
    assert denies_access(@citizen, @assigned_root_tag, :update)
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

  # Tag Scopes!
  #
  #   Root gets all the tags
  #   Tag admins and partner admins get a mix of public tags and the tags they can access
  #   Everyone else, gets public tags only

  def test_scope
    @all_tags = [@public_tag, @assigned_root_tag, @unassigned_root_tag].sort_by(&:id)
    @tag_admin_tags = [@public_tag, @assigned_root_tag].sort_by(&:id)
    @partner_admin_tags = [@public_tag]
    @citizen_tags = [@public_tag]

    assert_equal(permitted_records(@root, Tag).sort_by(&:id), @all_tags)
    # assert_equal(permitted_records(@tag_admin, Tag).sort_by(&:id), @tag_admin_tags)
    # assert_equal(permitted_records(@partner_admin, Tag).sort_by(&:id), @partner_admin_tags)
    # assert_equal(permitted_records(@citizen, Tag).sort_by(&:id), @citizen_tags)
  end
end
