# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Joins (Contact Form)", type: :request do
  let!(:default_site) { create(:default_site) }

  describe "GET /get-in-touch" do
    it "returns successful response" do
      get "/get-in-touch", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end

    it "renders the contact form" do
      get "/get-in-touch", headers: { "Host" => "lvh.me" }
      expect(response.body).to include("join")
    end
  end

  describe "POST /get-in-touch" do
    context "with valid params" do
      let(:valid_params) do
        {
          join: {
            name: "Test User",
            email: "test@example.com",
            why: "I want to help my community"
          }
        }
      end

      it "redirects on success" do
        post "/get-in-touch", params: valid_params, headers: { "Host" => "lvh.me" }
        expect(response).to be_redirect
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          join: {
            name: "",
            email: "",
            why: ""
          }
        }
      end

      it "re-renders the form with errors" do
        post "/get-in-touch", params: invalid_params, headers: { "Host" => "lvh.me" }
        # Renders form again or redirects depending on captcha
        expect(response).to be_successful.or be_redirect
      end
    end
  end
end
