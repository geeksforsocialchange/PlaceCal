# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminSiteTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @tag = create(:partnership)
    @site = create :site

    @neighbourhood_one = neighbourhoods[1].to_s.tr('w', 'W')
    @neighbourhood_two = neighbourhoods[2].to_s.tr('w', 'W')

    @sites_neighbourhood = create(:sites_neighbourhood,
                                  site: @site,
                                  neighbourhood: neighbourhoods[1])

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on site form' do
    click_link 'Sites'
    click_link 'Add New Site'

    site_admin = select2_node 'site_site_admin'
    select2 @root_user.to_s, xpath: site_admin.path
    assert_select2_single @root_user.to_s, site_admin

    # this select2 node will only appear when creating the site
    neighbourhood_main = select2_node 'site_sites_neighbourhood_neighbourhood_id'
    select2 @neighbourhood_one, xpath: neighbourhood_main.path
    assert_select2_single @neighbourhood_one, neighbourhood_main

    # because of the nested forms we get an array of node
    # the link adds a select2_node to the end of the array
    click_link 'Add neighbourhood'
    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    select2 @neighbourhood_two, xpath: service_areas[-1].path
    assert_select2_single @neighbourhood_two, service_areas[0]

    tags = select2_node 'site_tags'
    select2 @tag.name, xpath: tags.path
    assert_select2_multiple [@tag.name_with_type], tags

    new_site_name = 'TEST_NAME_123'
    fill_in 'Name', with: new_site_name
    fill_in 'Domain', with: 'https://test.com'
    fill_in 'Slug', with: 'eeew'
    click_button 'Create Site'

    click_link 'Sites'
    click_link new_site_name

    # check that data persists
    site_admin = select2_node 'site_site_admin'
    assert_select2_single @root_user.to_s, site_admin

    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    assert_select2_single @neighbourhood_two, service_areas[0]

    tags = select2_node 'site_tags'
    assert_select2_multiple [@tag.name_with_type], tags
  end
  test 'primary neighbourhood not rendering on other neighbourhoods section' do
    click_link 'Sites'
    await_datatables

    click_link @site.name

    # wait for some bit of the page to load first
    find :xpath, '//input[@value="Update Site"]', wait: 100

    # now try to grab these
    service_areas = all(:css, '.sites_neighbourhoods .select2-container', wait: 1)

    msg = \
      '@site should only have a primary neighbourhood, ' \
      'if this fails either this is now rendering where ' \
      'it should\'t or another neighborhood has been added ' \
      'at setup and the test should be adjusted'

    assert_predicate service_areas.length, :zero?, msg
  end
end
