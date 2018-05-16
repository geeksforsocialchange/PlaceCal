# frozen_string_literal: true

require 'test_helper'

class Admin::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = create(:site)
    @root = create(:root)
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Site Index
  #
  #   Show every Site for roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_sites_url
    assert_response :success
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_sites_url
    assert_redirected_to admin_root_url
  end

  # New & Create Site
  #
  #   Allow roots to create new Sites
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_new_for(%i[root]) do
    get new_admin_site_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Site.count') do
      post admin_sites_url,
           params: { site: attributes_for(:site) }
    end
  end

  # Edit & Update Site
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root]) do
    get edit_admin_site_url(@site)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root]) do
    patch admin_site_url(@site),
          params: { site: attributes_for(:site) }
    # Redirect to main partner screen
    assert_redirected_to admin_sites_url
  end

  # Delete Site
  #
  #   Allow roots to delete all Sites
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_destroy_for(%i[root]) do
    assert_difference('Site.count', -1) do
      delete admin_site_url(@site)
    end

    assert_redirected_to admin_sites_url
  end
end
