# frozen_string_literal: true

require_relative './application_system_test_case'

class CreateSelect2InputTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  # setup do
  #   server = Capybara.current_session.server
  #   app_routes = Rails.application.routes
  #   app_routes.default_url_options[:host] = server.host
  #   app_routes.default_url_options[:port] = server.port
  # end

  test 'visiting a calendars form' do
    # set up
    given_a_root_user_exists
    given_the_default_site_exists

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
    click_link 'Calendars'
    save_and_open_screenshot
    click_link 'Add New Calendar'
    save_and_open_screenshot
    select2_open label: 'Partner Organiser'
    save_and_open_screenshot
  end

  def given_a_root_user_exists
    create :root, email: 'root@lvh.me'
  end

  def given_the_default_site_exists
    create_default_site
  end
end
