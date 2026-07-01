# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin profile email preferences", type: :request do
  let(:user) { create(:citizen_user) }

  before { sign_in user }

  describe "GET /profile" do
    it "shows every registered email list" do
      get admin_profile_url(host: admin_host)

      expect(response).to be_successful
      EmailList.all.each do |list|
        expect(response.body).to include(list.name)
      end
    end
  end

  describe "PATCH /users/:id/update_profile" do
    it "records subscription changes with the profile_page source and the user as actor" do
      patch update_profile_admin_user_url(user, host: admin_host),
            params: { user: { first_name: user.first_name,
                              email_subscriptions: { partner_digest: "0", partnership_updates: "1" } } }

      expect(response).to redirect_to(admin_profile_path)
      expect(EmailSubscription.subscribed?(user, :partner_digest)).to be false
      expect(EmailSubscription.subscribed?(user, :partnership_updates)).to be true

      event = EmailSubscriptionEvent.last
      expect(event.source).to eq "profile_page"
      expect(event.actor).to eq user
    end

    it "leaves subscriptions untouched when the params are absent" do
      expect do
        patch update_profile_admin_user_url(user, host: admin_host),
              params: { user: { first_name: "Untouched" } }
      end.not_to change(EmailSubscription, :count)
    end
  end
end
