# frozen_string_literal: true

require 'test_helper'

class DeviseRedirectTest < ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  include EmailHelper

  setup do
    create :root, email: 'root@placecal.org'
    create_default_site
  end

  test 'logging in takes user to admin site' do
    visit 'http://lvh.me/users/sign_in'

    fill_in 'Email', with: 'root@placecal.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    # has redirected to admin site
    assert_equal 'http://admin.lvh.me/', current_url
  end

  test 'reset password' do
    visit 'http://lvh.me/users/sign_in'
    click_link 'Forgot your password?'

    fill_in 'Email', with: 'root@placecal.org'
    click_button 'Submit'

    # this now stays on the password reset page
    assert_selector '.alert-success',
                    text: 'If a PlaceCal account is associated with the submitted email address, password reset instructions have been sent.'
    assert_equal 'http://lvh.me/users/password/new', current_url

    click_link 'Admin log in'
    assert_equal 'http://lvh.me/users/sign_in', current_url

    # now pick up the reset email and extract the link
    email = last_email_delivered
    assert email, 'Expected email is missing'

    link = extract_link_from(email)
    assert link, 'Missing link in email?'

    # do the reset
    visit link
    fill_in 'New password', with: 'password2'
    fill_in 'Confirm new password', with: 'password2'
    click_button 'Change my password'

    # we are now logged in
    assert_selector '.alert-success', text: 'Your password has been changed successfully. You are now signed in.'
    assert_equal 'http://admin.lvh.me:3000/', current_url
  end

  test 'invitation to set password' do
    visit 'http://lvh.me/users/sign_in'

    # log in
    fill_in 'Email', with: 'root@placecal.org'
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    assert_selector '.alert-success', text: 'Signed in successfully.'

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
    assert_selector '.alert-success', text: 'User has been created! An invite has been sent'
    click_button 'Sign out'

    # accept invitation
    email = last_email_delivered
    assert email, 'No email sent'

    invitation_url = extract_link_from(email)
    assert invitation_url, 'Could not find invitation URL in email'

    # set password
    visit invitation_url
    fill_in 'New password', with: 'password'
    fill_in 'Repeat password', with: 'password'
    click_button 'Set password'

    # user should be logged in
    assert_equal 'http://admin.lvh.me:3000/', current_url
    assert_selector '.alert-success', text: 'Your password was set successfully. You are now signed in'
  end
end
