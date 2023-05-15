# frozen_string_literal: true

require 'test_helper'

class SitesIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    create_default_site
    @root = create(:root)
    @site_admin = create(:user)
    @site = create(:site, slug: 'hulme', site_admin: @site_admin)
    @neighbourhood = create(:neighbourhood)
    @sites_neighbourhood = create(:sites_neighbourhood,
                                  site: @site,
                                  neighbourhood: @neighbourhood)
  end

  test 'load different pages based on subdomain' do
    # Default: get home page
    get 'http://lvh.me'
    assert_template 'pages/home'
    # If there's no site, also get home
    get 'http://no-site-set.lvh.me'
    assert_redirected_to 'http://lvh.me/'
    # If there's a match, display a custom homepage
    get 'http://hulme.lvh.me'
    assert_template 'sites/default'
  end

  test 'basic page content shows up' do
    get 'http://hulme.lvh.me'
    assert_select 'h1',
                  'PlaceCal is a community events calendar where you can find everything near you, all in one place.'
    assert_select 'h2', "PlaceCal is working to make #{@site.place_name} a better connected neighbourhood."
    assert_select 'p', @site.description
    assert_select 'strong', @site_admin.full_name
    assert_select 'strong', @site_admin.phone
    assert_select 'strong', @site.site_admin.email
    assert_select 'h3', 'Adding Your Events'
    # assert_select 'h3', 'Getting Online'
    assert_select 'h3', 'PlaceCal Support'
    # assert_select 'p', 'Information about getting online coming soon.'
  end

  test 'find placecal page shows sites with primary neighbourhood' do
    get find_placecal_url
    assert_select '.neighbourhood_home_card__name', @site.place_name

    url = assert_select('.neighbourhood_home_card__link')[1]['href']
    assert_equal url, "http://#{@site.slug}.lvh.me:3000/"
  end

  test 'tag cards are hidden by default' do
    get 'http://hulme.lvh.me'

    assert_select '.help__computer_access', count: 0
    assert_select '.help__free_public_wifi', count: 0
  end

  test 'show computer access card when partners are tagged for it' do
    tag = create(:tag, name: 'computers')
    @site.tags << tag

    partner = build(:partner)
    partner.service_area_neighbourhoods << @neighbourhood
    partner.tags << tag
    partner.save!

    get 'http://hulme.lvh.me'

    assert_select '.help__computer_access'

    url = partner_path(partner)
    selector = ".help__computer_access a[href='#{url}']"
    assert_select selector
  end

  test 'show public wifi card when partners are tagged for it' do
    tag = create(:tag, name: 'wifi')
    @site.tags << tag

    partner = build(:partner)
    partner.service_area_neighbourhoods << @neighbourhood
    partner.tags << tag
    partner.save!

    get 'http://hulme.lvh.me'
    assert_select '.help__free_public_wifi'

    url = partner_path(partner)
    selector = ".help__free_public_wifi a[href='#{url}']"
    assert_select selector
  end

  test 'mossley page works' do
    mossley = create(:site, slug: 'mossley')
    get 'http://mossley.lvh.me'
    assert_response :success
    assert_includes response.body, 'Marvellous Mossley'
  end
end
