# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin partner verification invites", type: :request do
  let(:admin) { create(:root_user) }

  before { sign_in admin }

  describe "POST /partners/:id/send_verification_invite" do
    it "emails the partner's contact and stamps the invite" do
      partner = create(:partner, partner_email: "contact@example.com")

      expect { post send_verification_invite_admin_partner_url(partner, host: admin_host) }
        .to have_enqueued_job(ActionMailer::MailDeliveryJob)
        .with("PartnerVerificationMailer", "invite", "deliver_now", anything)

      partner.reload
      expect(partner.verification_invite_email).to eq "contact@example.com"
      expect(partner.verification_invite_sent_at).to be_within(1.minute).of(Time.current)
    end

    it "warns when the partner has no contact email" do
      partner = create(:partner, partner_email: nil, public_email: nil, admin_email: nil)

      post send_verification_invite_admin_partner_url(partner, host: admin_host)

      expect(partner.reload.verification_invite_sent_at).to be_nil
      follow_redirect!
      expect(response.body).to include(CGI.escapeHTML(
                                         I18n.t("admin.partners.send_verification_invite.no_contact_email")
                                       ))
    end
  end

  describe "consent basis at partner creation" do
    it "records the chosen basis against the new partner" do
      address = create(:riverside_address)

      post admin_partners_url(host: admin_host), params: {
        partner: {
          name: "Brand New Partner",
          summary: "A new community group",
          consent_basis: "asked_in_person",
          address_attributes: address.slice(:street_address, :city, :postcode)
        }
      }

      partner = Partner.find_by(name: "Brand New Partner")
      expect(partner).to be_present, response.body[0, 500]
      consent = partner.partner_consents.last
      expect(consent.basis).to eq "asked_in_person"
      expect(consent.recorded_by).to eq admin
    end
  end
end
