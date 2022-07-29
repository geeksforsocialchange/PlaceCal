# frozen_string_literal: true

require_relative './application_system_test_case'

class CalendarFormTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    create_default_site
    create :root, email: 'root@lvh.me'
    @partner = create(:partner)
    @partner_two = create(:ashton_partner)

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on calendars form' do
    click_sidebar 'calendars'

    # create a new Calendar
    click_link 'Add New Calendar'

    await_select2
    partner_orginiser = select2_node 'calendar_partner'
    select2 @partner.name, xpath: partner_orginiser.path
    assert_select2_single @partner.name, partner_orginiser

    default_location = select2_node 'calendar_place'
    select2 @partner_two.name, xpath: default_location.path
    assert_select2_single @partner_two.name, default_location

    fill_in 'Name', with: 'test cal'
    fill_in 'URL', with: 'http://test.com/events.ics'
    click_button 'Create Calendar'

    # check that select2 has rendered and is displaying correct data
    click_sidebar 'calendars'
    await_datatables
    click_link 'test cal'
    await_select2

    partner_orginiser = select2_node 'calendar_partner'
    assert_select2_single @partner.name, partner_orginiser

    default_location = select2_node 'calendar_place'
    assert_select2_single @partner_two.name, default_location
  end
end
