# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerDigestMailer, type: :mailer do
  let(:partner) { create(:partner, name: "Riverside Community Hub") }
  let(:user) { create(:partner_admin, partner: partner, partner_digest_last_sent_at: 90.days.ago) }

  def body_of(email)
    email.parts.map(&:decoded).join
  end

  describe "#digest" do
    let(:email) { described_class.digest(user) }

    it "is multipart with HTML and plain-text parts" do
      expect(email.parts.map(&:mime_type)).to contain_exactly("text/html", "text/plain")
    end

    it "includes the confirm, preferences, sign-in and password reset links in both parts" do
      email.parts.each do |part|
        expect(part.decoded).to include("confirm-partner-info")
        expect(part.decoded).to include("email-preferences")
        expect(part.decoded).to include("/users/sign_in")
        expect(part.decoded).to include("/users/password/new")
      end
    end

    it "carries the one-click unsubscribe headers from the guard" do
      email.deliver_now
      expect(email.header["List-Unsubscribe-Post"].value).to eq "List-Unsubscribe=One-Click"
    end

    it "is suppressed for a user unsubscribed from partner_digest" do
      EmailSubscription.set(user, :partner_digest, false, source: :unsubscribe_link)

      expect { described_class.digest(user).deliver_now }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end

    context "calendar state variants" do
      it "renders the healthy variant with upcoming events" do
        create(:calendar, organiser: partner, last_import_at: 1.day.ago)
        create(:event, organiser: partner, dtstart: 3.days.from_now, summary: "Drop-in gardening morning")

        body = body_of(email)
        expect(body).to include(I18n.t("mailers.partner_digest.healthy.status"))
        expect(body).to include("Drop-in gardening morning")
      end

      it "renders the failing variant with a plain-language reason" do
        create(:calendar, organiser: partner).update!(calendar_state: "bad_source")

        expect(body_of(email)).to include(I18n.t("mailers.partner_digest.failing.reasons.bad_source"))
      end

      it "renders the no-calendar variant without implying breakage" do
        expect(body_of(email)).to include(I18n.t("mailers.partner_digest.no_calendar.status"))
      end
    end

    context "intro variants" do
      it "uses the extended first-contact intro when no digest has ever been sent" do
        user.update!(partner_digest_last_sent_at: nil)

        body = body_of(described_class.digest(user))
        expect(body).to include(I18n.t("mailers.partner_digest.first_contact.what_is_placecal"))
        expect(body).not_to include(I18n.t("mailers.partner_digest.intro"))
      end

      it "uses the standard intro for subsequent digests" do
        body = body_of(email)
        expect(body).to include(I18n.t("mailers.partner_digest.intro"))
        expect(body).not_to include(I18n.t("mailers.partner_digest.first_contact.what_is_placecal"))
      end
    end
  end
end
