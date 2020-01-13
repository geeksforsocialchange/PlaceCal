# frozen_string_literal: true

require 'test_helper'

class AdminSitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @site = create(:site)
    @site_admin = @site.site_admin
    @neighbourhoods = create_list(:neighbourhood, 5)
    host! 'admin.lvh.me'
  end

  test 'create a site through the admin page' do
    # TODO: add capybara so we can get this junk working
  end

  test 'root users see appropriate fields' do
    sign_in(@root)
    get edit_admin_site_path(@site)

    # See every field
    assert_select 'label', 'Name *'
    assert_select 'label', 'Place name'
    assert_select 'label', 'Tagline'
    assert_select 'label', 'Domain *'
    assert_select 'label', 'Slug *'
    assert_select 'label', 'Description'
    assert_select 'label', 'Site admin'

    assert_select 'label', 'Theme'
    assert_select 'label', 'Logo'
    assert_select 'label', 'Footer logo'
    assert_select 'label', 'Hero image'
    assert_select 'label', 'Hero image credit'

    # See all neighbourhoods
    assert_select '.site__neighbourhoods' do
      assert_select 'label', 5
    end
  end

  test 'site admin users see appropriate fields' do
    sign_in(@site_admin)
    @site_admin.neighbourhoods << @neighbourhoods.first
    @site_admin.neighbourhoods << @neighbourhoods.second
    get edit_admin_site_path(@site)

    # See just appropriate fields
    assert_select 'label', 'Name *'
    assert_select 'label', 'Place name'
    assert_select 'label', 'Tagline'
    assert_select 'label', text: 'Domain *', count: 0
    assert_select 'label', text: 'Slug *', count: 0
    assert_select 'label', 'Description'
    assert_select 'label', text: 'Site admin', count: 0

    assert_select 'label', text: 'Theme', count: 0
    assert_select 'label', text: 'Logo', count: 0
    assert_select 'label', text: 'Footer logo', count: 0
    assert_select 'label', 'Hero image'
    assert_select 'label', 'Hero image credit'

    # See just neighbourhoods they admin
    assert_select '.site__neighbourhoods' do
      assert_select 'label', 2
    end
  end
end
