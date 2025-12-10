# frozen_string_literal: true

require 'test_helper'

class Admin::SupporterControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supporter = create(:supporter)
    @root = create(:root)
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Supporter Index
  #
  #   Show every Supporter for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_supporters_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_supporters_url
    assert_redirected_to admin_root_url
  end

  # New & Create Supporter
  #
  #   Allow roots to create new Supporters
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[root]) do
    get new_admin_supporter_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Supporter.count') do
      post admin_supporters_url,
           params: { supporter: attributes_for(:supporter) }
    end
  end

  # Edit & Update Supporter
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_supporter_url(@supporter)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_supporter_url(@supporter),
          params: { supporter: attributes_for(:supporter) }
    # Redirect to main partner screen
    assert_redirected_to admin_supporters_url
  end

  # Delete Supporter
  #
  #   Allow roots to delete all Supporters
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Supporter.count', -1) do
      delete admin_supporter_url(@supporter)
    end

    assert_redirected_to admin_supporters_url
  end

  it_denies_access_to_destroy_for(%i[citizen]) do
    assert_no_difference('Supporter.count') do
      delete admin_supporter_url(@supporter)
    end

    assert_redirected_to admin_root_url
  end
end
