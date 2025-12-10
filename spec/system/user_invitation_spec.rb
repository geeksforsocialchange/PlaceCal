# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Invitation Flow', :slow, type: :system do
  let(:admin_user) { create(:root_user, email: 'admin@placecal.org', password: 'password') }

  before do
    create_default_site

    # Configure URL options from Capybara session
    server = Capybara.current_session.server
    app_routes = Rails.application.routes
    app_routes.default_url_options[:host] = server.host
    app_routes.default_url_options[:port] = server.port
    app_routes.default_url_options[:protocol] = 'http'
  end

  it 'allows admin to invite a user who can then set their password' do
    # Log in as admin
    visit '/users/sign_in'
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
    fill_in 'Email', with: 'new.user@placecal.org'
    choose 'Root: Can do everything'
    click_button 'Invite'

    expect(page).to have_selector('.alert-success', text: 'User has been created! An invite has been sent')

    click_button 'Sign out'

    # Get the invitation email
    email = ActionMailer::Base.deliveries.last
    expect(email).to be_present

    # Extract invitation link from email
    body = email.body.parts.first.body.raw_source
    invitation_url = body[%r{https?://[^\s]+invitation_token=[^\s]+}]
    expect(invitation_url).to be_present

    # Accept invitation
    visit invitation_url
    fill_in 'New password', with: 'password123'
    fill_in 'Repeat password', with: 'password123'
    click_button 'Set password'

    expect(page).to have_selector('.alert-success', text: 'Your password was set successfully. You are now signed in')
  end
end
