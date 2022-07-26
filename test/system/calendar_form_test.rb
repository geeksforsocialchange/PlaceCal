# frozen_string_literal: true

require_relative './application_system_test_case'

class CalendarFormTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    create_default_site
    create :root, email: 'root@lvh.me'
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

  test 'select2 inputs on calendars form' do
    click_sidebar 'calendars'
    click_link 'Add New Calendar'

    # test that select2 has rendered and is single
    await_select2
    partner_orginiser = select2_node 'calendar_partner'
    default_location = select2_node 'calendar_place'

    select2 @partner.name, xpath: partner_orginiser.path
    assert_select2_single @partner.name, partner_orginiser

    select2 @partner_two.name, xpath: default_location.path
    assert_select2_single @partner_two.name, default_location

    # create a new Calendar
    fill_in 'Name', with: 'test cal'
    fill_in 'URL', with: 'http://test.com/events.ics'
    click_button 'Create Calendar'

    # open edit form for new calendar to see if select2 has rendered and is displaying correct data
    click_sidebar 'calendars'
    await_datatables
    click_link 'test cal'
    await_select2
    partner_orginiser = select2_node 'calendar_partner'
    default_location = select2_node 'calendar_place'
    assert_select2_single @partner.name, partner_orginiser
    assert_select2_single @partner_two.name, default_location
  end
end
