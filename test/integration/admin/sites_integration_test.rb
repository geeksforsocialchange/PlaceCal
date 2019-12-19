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

  test 'root users see all secondary neighbourhoods' do
    sign_in(@root)
    get edit_admin_site_path(@site)
    assert_select '.site__neighbourhoods' do
      assert_select 'label', 5
    end
  end

  test 'site admin users see neighbourhoods they are admin of' do
    sign_in(@site_admin)
    @site_admin.neighbourhoods << @neighbourhoods.first
    @site_admin.neighbourhoods << @neighbourhoods.second
    get edit_admin_site_path(@site)
    assert_select '.site__neighbourhoods' do
      assert_select 'label', 2
    end
  end
end
