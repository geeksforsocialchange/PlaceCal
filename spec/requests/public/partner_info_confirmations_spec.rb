# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partner info confirmations", type: :request do
  let(:partner) { create(:partner, name: "Riverside Community Hub") }
  let(:other_partner) { create(:partner, name: "Oldtown Library") }
  let(:user) { create(:user).tap { |u| u.partners << [partner, other_partner] } }
  let(:token) { PartnerInfoConfirmationsController.token_for(user) }
  let(:host) { "lvh.me" }

  describe "GET /confirm-partner-info" do
    it "lists the partners being confirmed" do
      get partner_info_confirmation_url(host: host, token: token)

      expect(response).to be_successful
      expect(response.body).to include(partner.name)
      expect(response.body).to include(other_partner.name)
    end

    it "renders the expired page for an invalid token" do
      get partner_info_confirmation_url(host: host, token: "nonsense")

      expect(response).to have_http_status(:gone)
    end

    it "rejects email-preferences tokens (different purpose)" do
      get partner_info_confirmation_url(host: host, token: EmailPreferencesController.token_for(user))

      expect(response).to have_http_status(:gone)
    end
  end

  describe "POST /confirm-partner-info" do
    it "records who confirmed, how, and when on every administered partner" do
      post partner_info_confirmation_url(host: host), params: { token: token }

      expect(response).to be_successful
      expect(response.body).to include(CGI.escapeHTML(I18n.t("partner_info_confirmations.confirmed.thanks")))

      [partner, other_partner].each do |confirmed|
        confirmed.reload
        expect(confirmed.info_confirmed_at).to be_within(1.minute).of(Time.current)
        expect(confirmed.info_confirmed_by).to eq user
        expect(confirmed.info_confirmed_source).to eq "digest_link"
      end
    end

    it "does nothing with an invalid token" do
      post partner_info_confirmation_url(host: host), params: { token: "nonsense" }

      expect(response).to have_http_status(:gone)
      expect(partner.reload.info_confirmed_at).to be_nil
    end
  end
end
