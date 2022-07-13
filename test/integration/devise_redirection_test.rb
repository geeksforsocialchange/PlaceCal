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
    click_button 'Send me reset password instructions'

    # has redirected to log in page with flash
    assert_selector '.alert-success', text: 'You will receive an email with instructions on how to reset your password in a few minutes.'
    assert_equal  'http://lvh.me/users/sign_in', current_url

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
    assert_equal  'http://admin.lvh.me:3000/', current_url
  end

  test 'change password (when logged in)' do
  end

  test 'invitation to set password' do
  end
end

