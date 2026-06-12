# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partner verifications", type: :request do
  let(:partner) do
    create(:partner, name: "Dalston Community Cafe", hidden: true,
                     hidden_reason: Partner::VERIFICATION_HOLD_REASON, hidden_blame_id: 1)
  end
  let(:token) { PartnerVerificationsController.token_for(partner) }
  let(:host) { "lvh.me" }

  describe "GET /verify-partner" do
    it "shows the landing page without verifying anything" do
      get partner_verification_url(host: host, token: token)

      expect(response).to be_successful
      expect(response.body).to include("Dalston Community Cafe")
      expect(partner.reload.verified_at).to be_nil
      expect(partner.hidden).to be true
    end

    it "renders the expired page for an invalid token" do
      get partner_verification_url(host: host, token: "nonsense")

      expect(response).to have_http_status(:gone)
    end
  end

  describe "POST /verify-partner" do
    it "publishes the partner and records consent" do
      post partner_verification_url(host: host), params: { token: token }

      expect(response).to be_successful
      partner.reload
      expect(partner.hidden).to be false
      expect(partner.verified_at).to be_present
      expect(partner.partner_consents.last.basis).to eq "verified_by_email"
    end

    it "is idempotent: verifying twice records consent once" do
      post partner_verification_url(host: host), params: { token: token }

      expect { post partner_verification_url(host: host), params: { token: token } }
        .not_to change(PartnerConsent, :count)
      expect(response).to be_successful
    end

    it "does nothing with an invalid token" do
      post partner_verification_url(host: host), params: { token: "nonsense" }

      expect(response).to have_http_status(:gone)
      expect(partner.reload.verified_at).to be_nil
    end

    it "records consent but does not unhide a partner hidden by a moderator" do
      partner.update!(hidden_reason: "Duplicate of another listing")

      post partner_verification_url(host: host), params: { token: token }

      partner.reload
      expect(partner.verified_at).to be_present
      expect(partner.partner_consents.last.basis).to eq "verified_by_email"
      expect(partner.hidden).to be true
    end
  end
end
