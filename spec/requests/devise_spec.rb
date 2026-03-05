# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise Pages", type: :request do
  # Devise auth pages redirect from subdomains to root domain (via devise_check_on_root_site).
  # Access them on the root domain with a default site present.
  let!(:default_site) { create(:default_site) }

  describe "GET /users/sign_in (login)" do
    it "returns successful response" do
      get new_user_session_url(host: "lvh.me")
      expect(response).to be_successful
    end

    it "renders the login form" do
      get new_user_session_url(host: "lvh.me")
      expect(response.body).to match(/sign.in|log.in|email|password/i)
    end
  end

  describe "GET /users/sign_in from admin subdomain" do
    it "redirects to root domain" do
      get new_user_session_url(host: "admin.lvh.me")
      expect(response).to be_redirect
    end
  end

  describe "GET /users/password/new (forgot password)" do
    it "returns successful response" do
      get new_user_password_url(host: "lvh.me")
      expect(response).to be_successful
    end
  end

  describe "GET /users/password/edit (reset password)" do
    it "renders with a reset token param" do
      get edit_user_password_url(host: "lvh.me", reset_password_token: "invalid")
      # Devise renders the form even with invalid token, error shown on submit
      expect(response).to be_successful
    end
  end

  describe "GET /users/invitation/accept (accept invitation)" do
    it "redirects without valid token" do
      get accept_user_invitation_url(host: "lvh.me", invitation_token: "invalid")
      # Devise invitable redirects if token is invalid
      expect(response).to be_redirect
    end
  end

  describe "GET /users/invitation/new (send invitation)" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    it "shows the invitation form" do
      get new_user_invitation_url(host: "lvh.me")
      expect(response).to be_successful
    end
  end
end
