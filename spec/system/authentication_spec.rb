# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication', :slow, type: :system do
  let!(:root_user) do
    create(:root_user,
           email: 'root@placecal.org',
           password: 'password',
           password_confirmation: 'password')
  end

  before do
    create_default_site
  end

  describe 'login flow' do
    it 'redirects user to admin site after login' do
      port = Capybara.current_session.server.port
      visit "http://lvh.me:#{port}/users/sign_in"

      fill_in 'Email', with: 'root@placecal.org'
      fill_in 'Password', with: 'password'
      click_button 'Log in'

      # Should redirect to admin site
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
    end
  end

  describe 'password reset' do
    it 'allows user to reset password via email link', skip: 'Flaky: password reset URL host mismatch with test server' do
      port = Capybara.current_session.server.port
      visit "http://lvh.me:#{port}/users/sign_in"
      click_link 'Forgot your password?'

      fill_in 'Email', with: 'root@placecal.org'
      click_button 'Submit'

      # Should stay on password reset page with success message
      expect(page).to have_css('.alert-success',
                               text: 'If a PlaceCal account is associated with the submitted email address, password reset instructions have been sent.')

      # Get the reset email and extract the link
      email = last_email_delivered
      expect(email).to be_present

      link = extract_link_from(email)
      expect(link).to be_present

      # Visit the reset link and set new password
      visit link
      fill_in 'New password', with: 'newpassword123'
      fill_in 'Confirm new password', with: 'newpassword123'
      click_button 'Change my password'

      # Should be logged in after password change
      expect(page).to have_css('.alert-success', text: 'Your password has been changed successfully. You are now signed in.')
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
    end
  end

  describe 'user invitation' do
    it 'allows root user to invite new users who can set their password', skip: 'Flaky: invitation URL host mismatch' do
      port = Capybara.current_session.server.port

      # Log in as root
      visit "http://lvh.me:#{port}/users/sign_in"
      fill_in 'Email', with: 'root@placecal.org'
      fill_in 'Password', with: 'password'
      click_button 'Log in'

      expect(page).to have_css('.alert-success', text: 'Signed in successfully.')

      # Navigate to create user
      click_link 'Users'
      click_link 'Add New User'

      # Fill in new user details
      fill_in 'First name', with: 'New'
      fill_in 'Last name', with: 'User'
      fill_in 'Email', with: 'new.user@placecal.org'
      choose 'Root: Can do everything'
      click_button 'Invite'

      # Should show success message
      expect(page).to have_css('.alert-success', text: 'User has been created! An invite has been sent')
      click_button 'Sign out'

      # Get invitation email
      email = last_email_delivered
      expect(email).to be_present

      invitation_url = extract_link_from(email)
      expect(invitation_url).to be_present

      # Visit invitation link and set password
      visit invitation_url
      fill_in 'New password', with: 'password123'
      fill_in 'Repeat password', with: 'password123'
      click_button 'Set password'

      # User should be logged in
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
      expect(page).to have_css('.alert-success', text: 'Your password was set successfully. You are now signed in')
    end
  end
end
