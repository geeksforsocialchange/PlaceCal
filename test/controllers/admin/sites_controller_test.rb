# frozen_string_literal: true

require 'test_helper'

class Admin::SitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @site = create(:site)
    @site_two = create(:site)
    @root = create(:root)
    @site_admin = @site.site_admin
    @citizen = create(:user)

    host! 'admin.lvh.me'
  end

  # Site Index
  #
  #   Show every Site for roots
  #   Show just user's sites for non-roots
  #   Redirect everyone else to admin_root_url

  it_allows_access_to_index_for(%i[root]) do
    get admin_sites_url
    assert_response :success
    # Will see both sites
    assert_select 'tbody tr', count: 2
  end

  it_allows_access_to_index_for(%i[site_admin]) do
    get admin_sites_url
    assert_response :success
    # Will just see their site
    assert_select 'tbody tr', count: 1
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

  it_denies_access_to_new_for(%i[site_admin citizen]) do
    get new_admin_site_url
    assert_redirected_to admin_root_url
  end

  it_allows_access_to_create_for(%i[root]) do
    assert_difference('Site.count') do
      post admin_sites_url,
           params: { site: attributes_for(:site) }
    end
  end

  it_denies_access_to_create_for(%i[site_admin citizen]) do
    assert_no_difference('Site.count') do
      post admin_sites_url,
           params: { site: attributes_for(:site) }
    end
  end

  # Edit & Update Site
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_root_url

  it_allows_access_to_edit_for(%i[root site_admin]) do
    get edit_admin_site_url(@site)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[root site_admin]) do
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

  it_denies_access_to_destroy_for(%i[site_admin citizen]) do
    assert_no_difference('Site.count') do
      delete admin_site_url(@site)
    end

    assert_redirected_to admin_root_url
  end
end
