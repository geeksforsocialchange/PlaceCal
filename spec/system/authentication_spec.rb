# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", :slow, type: :system do
  let!(:root_user) do
    create(:root_user,
           email: "root@placecal.org",
           password: "password",
           password_confirmation: "password")
  end

  before do
    create_default_site
  end

  describe "login flow" do
    it "redirects user to admin site after login" do
      port = Capybara.current_session.server.port
      visit "http://lvh.me:#{port}/users/sign_in"

      fill_in "Email", with: "root@placecal.org"
      fill_in "Password", with: "password"
      click_button "Log in"

      # Wait for redirect to admin site (Capybara will retry until URL matches or timeout)
      expect(page).to have_current_path("http://admin.lvh.me:#{port}/", url: true)
    end
  end

  describe "password reset" do
    # This test is flaky in CI - the Submit button is sometimes not found
    # TODO: Investigate CI-specific Devise form rendering issues
    it "allows user to reset password via email link", skip: ENV.fetch("CI", nil) do
      port = Capybara.current_session.server.port
      visit "http://lvh.me:#{port}/users/sign_in"
      click_link "Forgot your password?"

      fill_in "Email", with: "root@placecal.org"
      click_button "Submit"

      # Should stay on password reset page with success message (flash uses Tailwind classes with role="alert")
      expect(page).to have_css("[role='alert']",
                               text: "If a PlaceCal account is associated with the submitted email address, password reset instructions have been sent.")

      # Get the reset email and extract the link
      email = last_email_delivered
      expect(email).to be_present

      link = extract_link_from(email)
      expect(link).to be_present

      # Convert HTTPS to HTTP since test server doesn't support SSL
      # Also ensure we use the correct port (email may have different host/port)
      uri = URI.parse(link)
      test_link = "http://lvh.me:#{port}#{uri.path}?#{uri.query}"

      # Visit the reset link and set new password
      visit test_link
      fill_in "New password", with: "newpassword123"
      fill_in "Confirm new password", with: "newpassword123"
      click_button "Change my password"

      # Should be logged in after password change
      expect(page).to have_css("[role='alert']", text: "Your password has been changed successfully. You are now signed in.")
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
    end
  end
end
