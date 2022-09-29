require_relative './application_system_test_case'

class CreateAdminUsersTest < ApplicationSystemTestCase
  setup do
    server = Capybara.current_session.server
    app_routes = Rails.application.routes

    # Use configuration from Capybara session so URLs are generated pointing at
    # the correct test server
    app_routes.default_url_options[:host] = server.host
    app_routes.default_url_options[:port] = server.port
    app_routes.default_url_options[:protocol] = 'http'
  end

  test 'visiting the index' do
    # set up
    given_a_root_user_exists
    given_the_default_site_exists

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_has_success_flash 'Signed in successfully.'

    # navigate to create user
    click_link 'Users'
    click_link 'Add New User'

    # fill in new user details
    fill_in 'First name', with: 'Root'
    fill_in 'Last name', with: 'User'
    fill_in 'Email', with: 'root.user@lvh.me'
    choose 'Root: Can do everything'
    click_button 'Invite'

    # that should be successful
    assert_has_success_flash 'User has been created! An invite has been sent'
    click_button 'Sign out'

    # accept invitation
    email = last_email_delivered
    assert email, 'No email sent'

    invitation_url = extract_invitation_link_from(email)
    # puts "invitation_url=#{invitation_url}"
    assert invitation_url, 'Could not find invitation URL in email'

    # set password
    visit invitation_url
    fill_in 'New password', with: 'password'
    fill_in 'Repeat password', with: 'password'
    click_button 'Set password'

    # user should be logged in
    assert_has_success_flash 'Your password was set successfully. You are now signed in'
    # TODO: verify we are on admin root dashboard
  end

  def given_a_root_user_exists
    create :root, email: 'root@lvh.me'
  end

  def given_the_default_site_exists
    create_default_site
  end

  def assert_has_success_flash(msg)
    assert_selector '.alert-success', text: msg
  end

  def last_email_delivered
    ActionMailer::Base.deliveries.last
  end

  def extract_invitation_link_from(email)
    body = email.body.parts.first.body.raw_source

    body =~ %r{^(https?://.*)$} && Regexp.last_match(1)
  end
end
