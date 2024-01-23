# frozen_string_literal: true

require 'test_helper'

class AdminSitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @another_root = create(:root)

    @site = create(:site)
    @another_site = create(:site, name: 'another', site_admin: @another_root)

    @site_admin = @site.site_admin

    @neighbourhoods = create_list(:neighbourhood, 5)
    @number_of_neighbourhoods = Neighbourhood.all.length

    @tag = create(:tag, type: 'Category')
    @partnership_tag = create(:partnership)

    host! 'admin.lvh.me'
  end

  test 'Site admin index has appropriate title' do
    sign_in(@root)
    get admin_sites_path
    assert_response :success

    assert_select 'title', text: 'Sites | PlaceCal Admin'
    assert_select 'h1', text: 'Sites'
  end

  test 'Admin site index shows all sites to signed in admin if none are assigned' do
    sign_in(@root)
    get admin_sites_path
    assert_response :success

    assert_select 'td', text: @another_site.name
    assert_select 'td', text: @site.name
  end

  test 'root : can get new site' do
    sign_in @root

    get new_admin_site_path

    assert_select 'title', text: 'New Site | PlaceCal Admin'
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
    assert_select 'label', 'Url *'
    assert_select 'label', 'Slug *'
    assert_select 'label', 'Description'
    assert_select 'label', 'Site admin'

    assert_select 'label', 'Theme'
    assert_select 'label', 'Logo'
    assert_select 'label', 'Footer logo'
    assert_select 'label', 'Hero image'
    assert_select 'label', 'Hero image credit'

    # See just neighbourhoods they admin
    # In short:
    # - Find the cocoon template for the Secondary Neighbourhoods <select> item
    # - Grep for all occurences of "option value=" which grabs only the first <option> tag (not the closing tag)
    # - That gives us all the neighbourhoods it is displaying
    #
    # Please replace this with Capybara in the future lol

    cocoon_select_template = assert_select('.add_fields').first['data-association-insertion-template']
    neighbourhoods_shown = cocoon_select_template.scan(/(option value=)/).size
    assert_equal neighbourhoods_shown, @number_of_neighbourhoods
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
    assert_select 'label', text: 'Url *', count: 1
    assert_select 'label', text: 'Slug *', count: 1
    assert_select 'label', 'Description'
    assert_select 'label', text: 'Site admin', count: 0

    assert_select 'label', text: 'Theme', count: 1
    assert_select 'label', text: 'Logo', count: 1
    assert_select 'label', text: 'Footer logo', count: 1
    assert_select 'label', 'Hero image'
    assert_select 'label', 'Hero image credit'
  end

  test 'site tags show up and display their type' do
    @site.tags << @partnership_tag
    @site_admin.tags << @partnership_tag

    sign_in(@site_admin)
    get edit_admin_site_path(@site)
    assert_response :success

    tag_options = assert_select 'div.site_tags option', count: 1, text: @partnership_tag.name_with_type

    tag = tag_options.first
    assert tag.attributes.key?('selected')
  end

  test 'new site image upload problem feedback' do
    sign_in @root

    new_site_params = {
      name: 'a new site',
      url: 'https://a-domain.placecal.org',
      slug: 'a-slug',
      logo: fixture_file_upload('bad-cat-picture.bmp'),
      footer_logo: fixture_file_upload('bad-cat-picture.bmp'),
      hero_image: fixture_file_upload('bad-cat-picture.bmp')
    }

    post admin_sites_path, params: { site: new_site_params }
    assert_not response.successful?

    assert_select 'h6', text: '3 errors prohibited this Site from being saved'

    # top of page form error box
    assert_select '#form-errors li', text: 'Logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select '#form-errors li',
                  text: 'Footer logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select '#form-errors li',
                  text: 'Hero image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, png'

    assert_select 'form .site_logo .invalid-feedback',
                  text: 'Logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select 'form .site_footer_logo .invalid-feedback',
                  text: 'Footer logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select 'form .site_hero_image .invalid-feedback',
                  text: 'Hero image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, png'
  end

  test 'update site image upload problem feedback' do
    sign_in @root

    site_params = {
      name: 'a new site',
      url: 'https://a-domain.placecal.org',
      slug: 'a-slug',
      logo: fixture_file_upload('bad-cat-picture.bmp'),
      footer_logo: fixture_file_upload('bad-cat-picture.bmp'),
      hero_image: fixture_file_upload('bad-cat-picture.bmp')
    }

    put admin_site_path(@site), params: { site: site_params }
    assert_not response.successful?

    assert_select 'h6', text: '3 errors prohibited this Site from being saved'

    # top of page form error box
    assert_select '#form-errors li', text: 'Logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select '#form-errors li',
                  text: 'Footer logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select '#form-errors li',
                  text: 'Hero image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, png'

    assert_select 'form .site_logo .invalid-feedback',
                  text: 'Logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select 'form .site_footer_logo .invalid-feedback',
                  text: 'Footer logo You are not allowed to upload "bmp" files, allowed types: svg, png'
    assert_select 'form .site_hero_image .invalid-feedback',
                  text: 'Hero image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, png'
  end
end
