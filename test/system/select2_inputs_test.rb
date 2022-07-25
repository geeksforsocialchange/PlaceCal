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

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'visiting a calendars form' do
    # save_and_open_screenshot

    within '.sidebar-sticky' do
      link = page.find(:css, 'a[href*="calendars"]')
      # puts link["href"]
      # this works but why does the calendar exist but not be clickable?
      visit link['href']
      #
      # click_link 'Calendars'
      # looks like this redirects to "calendars/new" because there is no Calendar
      # maybe this won't matter!? I don't think any of the inputs take calendars
      #
      # For some reason we have a calendar but theres some strange error in the
      # events part of the table and you can't click through to edit it.
    end

    # save_and_open_screenshot
    click_link 'Add New Calendar'
    partner_orginiser = page.all(:css, '.select2-container')[0]
    default_location = page.all(:css, '.select2-container')[1]
    # save_and_open_screenshot
    # select2_open from: 'Partner Organiser'
    # select2 'Community Group 1', xpath: partner_orginiser.path
    # select2 'Community Group 2', xpath: partner_orginiser.path
    # within :xpath, partner_orginiser.path do
    #   assert_selector '.select2-selection__rendered', text: 'Community Group 2'
    # end
    assert_select2_single partner_orginiser, 'Community Group 2'
    assert_select2_single default_location, 'Community Group 3'

    # select2s = page.all(:css, '.select2-container')
    # select2 'Community Group 1', xpath: default_location.path
    # select2 'Community Group 3', xpath: default_location.path
    # within :xpath, default_location.path do
    #   assert_selector '.select2-selection__rendered', text: 'Community Group 3'
    # end
    # select2-selection__rendered

    # select2_open css: '#calendar_place_id' # error
    # Error:
    # Select2InputTest#test_visiting_a_calendars_form:
    # Capybara::Ambiguous: Ambiguous match, found 2 elements matching visible css "label:not(.select2-offscreen)" with text "Default location"
    #   test/system/select2_inputs_test.rb:57:in `block in <class:Select2InputTest>'

    save_and_open_screenshot
  end
  def assert_select2_single(node, option)
    select2 option, xpath: node.path
    within :xpath, node.path do
      assert_selector '.select2-selection__rendered', text: option
    end
  end
end
