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

      # Should redirect to admin site
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
    end
  end

  describe "password reset" do
    it "allows user to reset password via email link" do
      port = Capybara.current_session.server.port
      visit "http://lvh.me:#{port}/users/sign_in"
      click_link "Forgot your password?"

      fill_in "Email", with: "root@placecal.org"
      click_button "Submit"

      # Should stay on password reset page with success message
      expect(page).to have_css(".alert-success",
                               text: "If a PlaceCal account is associated with the submitted email address, password reset instructions have been sent.")

      # Get the reset email and extract the link
      email = last_email_delivered
      expect(email).to be_present

      link = extract_link_from(email)
      expect(link).to be_present

      # Visit the reset link and set new password
      visit link
      fill_in "New password", with: "newpassword123"
      fill_in "Confirm new password", with: "newpassword123"
      click_button "Change my password"

      # Should be logged in after password change
      expect(page).to have_css(".alert-success", text: "Your password has been changed successfully. You are now signed in.")
      expect(current_url).to eq("http://admin.lvh.me:#{port}/")
    end
  end
end
