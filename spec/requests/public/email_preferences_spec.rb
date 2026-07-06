# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Email Preferences", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:token) { EmailPreferencesController.token_for(user) }
  let(:host) { "lvh.me" }

  describe "GET /email-preferences" do
    it "shows every registered list" do
      get email_preferences_url(host: host, token: token)

      expect(response).to be_successful
      EmailList.all.each do |list|
        expect(response.body).to include(list.name)
      end
    end

    it "renders the expired page for a garbage token" do
      get email_preferences_url(host: host, token: "nonsense")

      expect(response).to have_http_status(:gone)
      expect(response.body).to include(I18n.t("email_preferences.expired.title"))
    end

    it "renders the expired page for an expired token" do
      expired_token = user.signed_id(purpose: :email_preferences, expires_in: 0.seconds)
      travel_to(1.minute.from_now) do
        get email_preferences_url(host: host, token: expired_token)
      end

      expect(response).to have_http_status(:gone)
    end

    it "rejects tokens signed for another purpose" do
      get email_preferences_url(host: host, token: user.signed_id(purpose: :something_else))

      expect(response).to have_http_status(:gone)
    end
  end

  describe "PATCH /email-preferences" do
    it "records the submitted preferences with the unsubscribe_link source" do
      patch email_preferences_url(host: host),
            params: { token: token,
                      email_subscriptions: { partner_digest: "0", partnership_updates: "1" } }

      expect(response).to redirect_to(email_preferences_path(token: token))
      expect(EmailSubscription.subscribed?(user, :partner_digest)).to be false
      expect(EmailSubscription.subscribed?(user, :partnership_updates)).to be true
      expect(EmailSubscriptionEvent.where(user: user).pluck(:source).uniq).to eq ["unsubscribe_link"]
    end

    it "does nothing with an invalid token" do
      patch email_preferences_url(host: host),
            params: { token: "nonsense", email_subscriptions: { partner_digest: "0" } }

      expect(response).to have_http_status(:gone)
      expect(EmailSubscription.count).to eq 0
    end
  end

  describe "POST /email-preferences/unsubscribe (RFC 8058 one-click)" do
    it "unsubscribes from the named list without CSRF or login" do
      post email_preferences_unsubscribe_url(host: host, token: token, list: :partner_digest),
           params: { "List-Unsubscribe" => "One-Click" }

      expect(response).to have_http_status(:ok)
      expect(EmailSubscription.subscribed?(user, :partner_digest)).to be false
    end

    it "rejects unknown lists" do
      post email_preferences_unsubscribe_url(host: host, token: token, list: :nonsense)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects invalid tokens" do
      post email_preferences_unsubscribe_url(host: host, token: "nonsense", list: :partner_digest)

      expect(response).to have_http_status(:gone)
    end
  end
end
