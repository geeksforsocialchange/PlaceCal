# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailListGuard, type: :mailer do
  let(:user) { create(:user) }

  before do
    stub_const("ListTestMailer", Class.new(ApplicationMailer) do
      email_list :partner_digest

      def digest(user)
        mail(to: user.email, subject: "Test digest") do |format|
          format.text { render plain: "hello" }
        end
      end
    end)

    stub_const("TransactionalTestMailer", Class.new(ApplicationMailer) do
      def notice(email)
        mail(to: email, subject: "Test notice") do |format|
          format.text { render plain: "hello" }
        end
      end
    end)
  end

  describe "a mailer with a declared list" do
    it "delivers to a subscribed user" do
      expect { ListTestMailer.digest(user).deliver_now }
        .to change(ActionMailer::Base.deliveries, :count).by(1)
    end

    it "sets the one-click unsubscribe headers (RFC 8058)" do
      email = ListTestMailer.digest(user).deliver_now

      expect(email.header["List-Unsubscribe"].value).to match(%r{\A<http.+email-preferences/unsubscribe.+>\z})
      expect(email.header["List-Unsubscribe-Post"].value).to eq "List-Unsubscribe=One-Click"
    end

    it "suppresses delivery to an unsubscribed user" do
      EmailSubscription.set(user, :partner_digest, false, source: :unsubscribe_link)

      expect { ListTestMailer.digest(user).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end

    it "suppresses delivery to addresses with no account" do
      stranger = build(:user, email: "nobody@example.com")

      expect { ListTestMailer.digest(stranger).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe "a mailer with no declared list (transactional)" do
    it "always delivers, even to a user unsubscribed from every list" do
      EmailList.all.each do |list|
        EmailSubscription.set(user, list.key, false, source: :unsubscribe_link)
      end

      expect { TransactionalTestMailer.notice(user.email).deliver_now }
        .to change(ActionMailer::Base.deliveries, :count).by(1)
      expect(ActionMailer::Base.deliveries.last.header["List-Unsubscribe"]).to be_nil
    end
  end

  describe "#email_preferences_url_for" do
    it "builds a signed preferences link for email footers" do
      url = ListTestMailer.new.email_preferences_url_for(user)

      expect(url).to include("email-preferences")
      token = Rack::Utils.parse_query(URI.parse(url).query)["token"]
      expect(User.find_signed(token, purpose: :email_preferences)).to eq user
    end
  end
end
