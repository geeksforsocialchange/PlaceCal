# frozen_string_literal: true

require_relative './application_system_test_case'

class Select2InputTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    # server = Capybara.current_session.server
    # app_routes = Rails.application.routes
    # app_routes.default_url_options[:host] = server.host
    # app_routes.default_url_options[:port] = server.port
    create_default_site
    create :root, email: 'root@lvh.me'
    # create :calendar
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partner_admin = create(:partner_admin)

    @partner = @partner_admin.partners.first
    @partner_two = create(:ashton_partner)
    @neighbourhood = @partner.address.neighbourhood
    @neighbourhood_admin.neighbourhoods << @neighbourhood

    @calendar = create(:calendar, partner: @partner, place: @partner)
    @address = create :address
    create :event, address: @address, calendar: @calendar
    create :tag
    create :tag_public

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'visiting a calendars form' do
    click_sidebar 'calendars'
    click_link 'Add New Calendar'

    # test that select2 has rendered and is single
    partner_orginiser = select2_node 'calendar_partner'
    default_location = select2_node 'calendar_place'

    select2 'Community Group 2', xpath: partner_orginiser.path
    assert_select2_single 'Community Group 2', partner_orginiser

    select2 'Community Group 3', xpath: default_location.path
    assert_select2_single 'Community Group 3', default_location

    # create a new Calendar
    fill_in 'Name', with: 'test cal'
    fill_in 'URL', with: 'http://test.com/events.ics'
    click_button 'Create Calendar'

    # open edit form for new calendar to see if select2 has rendered and is displaying correct data
    click_sidebar 'calendars'
    await_datatables
    click_link 'test cal'
    partner_orginiser = select2_node 'calendar_partner'
    default_location = select2_node 'calendar_place'
    assert_select2_single 'Community Group 2', partner_orginiser
    assert_select2_single 'Community Group 3', default_location
  end

  test 'visiting a users form' do
    click_sidebar 'users'
    await_datatables

    # edit a root user because they have access to all potential select2 inputs
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link('Place')
    end
    partners = select2_node 'user_partners'
    neighbourhoods = select2_node 'user_neighbourhoods'
    tags = select2_node 'user_tags'
    select2 'Community Group 1', 'Community Group 2', xpath: partners.path
    assert_select2_multiple ['Community Group 1', 'Community Group 2'], partners
    select2 'Ashton Hurst (Ward)', 'Ashton Hurst, Tameside (Ward)', xpath: neighbourhoods.path
    assert_select2_multiple ['Ashton Hurst (Ward)', 'Ashton Hurst, Tameside (Ward)'], neighbourhoods
    select2 'Hulme 1', 'Hulme 2', xpath: tags.path
    assert_select2_multiple ['Hulme 1', 'Hulme 2'], tags
    click_button 'Update'

    click_sidebar 'users'
    await_datatables

    # return to user to check data is intact
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link('Place')
    end
    partners = select2_node 'user_partners'
    neighbourhoods = select2_node 'user_neighbourhoods'
    tags = select2_node 'user_tags'
    assert_select2_multiple ['Community Group 1', 'Community Group 2'], partners
    assert_select2_multiple ['Ashton Hurst (Ward)', 'Ashton Hurst, Tameside (Ward)'], neighbourhoods
    assert_select2_multiple ['Hulme 1', 'Hulme 2'], tags
  end

  test 'visiting a neighbourhoods form' do
    click_sidebar 'neighbourhoods'
    await_datatables
    click_link '298486374'
    save_and_open_screenshot
  end

  def click_sidebar(href)
    # I think the icons are interfering with click_link
    within '.sidebar-sticky' do
      link = page.find(:css, "a[href*='#{href}']")
      visit link['href']
    end
  end

  def await_datatables(time = 15)
    page.find(:css, '#datatable_info', wait: time)
  end

  def all_select2
    page.all(:css, '.select2-container')
  end

  def select2_node(stable_identifier)
    within ".#{stable_identifier}" do
      find(:css, '.select2-container')
    end
  end

  def assert_select2_single(option, node)
    within :xpath, node.path do
      assert_selector '.select2-selection__rendered', text: option
    end
  end

  def assert_select2_multiple(options_array, node)
    # The data is stored like this.
    # "×Computer Access\n×Free WiFi\n×GM Systems Changers"
    # The order is unpredictable so we can't build version from our options to test against
    # instead copy the data, then pull out the options and joining characters
    # If we are left with nothing then the options and stored data match
    within :xpath, node.path do
      assert_selector '.select2-selection__choice', count: options_array.length
      rendered = find(:css, '.select2-selection__rendered').text.gsub('×', '').gsub("\n", '')
      options_array.each do |opt|
        rendered = rendered.gsub(opt, '')
      end
      assert_equal('', rendered, "'#{rendered}' is in the selected data but not in the options passed to this test")
    end
  end
end
