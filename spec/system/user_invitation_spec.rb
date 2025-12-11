# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Invitation Flow', :slow, type: :system do
  let(:admin_user) { create(:root_user, email: 'admin@placecal.org', password: 'password', password_confirmation: 'password') }
  # Use unique email to avoid conflicts with other tests
  let(:invited_user_email) { "invited.user.#{SecureRandom.hex(4)}@placecal.org" }

  before do
    create_default_site
  end

  it 'allows admin to invite a user who can then set their password' do
    # Log in as admin via admin subdomain
    port = Capybara.current_session.server.port
    visit "http://admin.lvh.me:#{port}/users/sign_in"
    fill_in 'Email', with: admin_user.email
    fill_in 'Password', with: 'password'
    click_button 'Log in'

    expect(page).to have_selector('.alert-success', text: 'Signed in successfully.')

    # Navigate to create user
    click_link 'Users'
    click_link 'Add New User'

    # Fill in new user details
    fill_in 'First name', with: 'New'
    fill_in 'Last name', with: 'User'
    fill_in 'Email', with: invited_user_email
    choose 'Root: Can do everything'
    click_button 'Invite'

    expect(page).to have_selector('.alert-success', text: 'User has been created! An invite has been sent')

    click_button 'Sign out'

    # Get the invitation email
    email = ActionMailer::Base.deliveries.last
    expect(email).to be_present

    # Extract invitation token from email body
    # Handle both HTML and text email parts
    body = email.body.parts.first.body.raw_source
    invitation_token = body[/invitation_token=([a-zA-Z0-9_-]+)/, 1]
    expect(invitation_token).to be_present, "Could not extract invitation token from email body: #{body[0..500]}"

    # Reset session to ensure clean state before accepting invitation
    # This prevents any lingering admin session from interfering
    Capybara.reset_sessions!

    # Build the invitation URL using the current test session's port
    # This is more reliable than using the URL from the email which may have
    # a different host/port depending on ActionMailer configuration timing
    visit "http://lvh.me:#{port}/users/invitation/accept?invitation_token=#{invitation_token}"
    fill_in 'New password', with: 'password123'
    fill_in 'Repeat password', with: 'password123'
    click_button 'Set password'

    expect(page).to have_selector('.alert-success', text: 'Your password was set successfully. You are now signed in')
  end
end
