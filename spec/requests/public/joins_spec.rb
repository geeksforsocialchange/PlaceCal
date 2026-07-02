# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Joins (Contact Form)", type: :request do
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
          contact_request: {
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
          contact_request: {
            name: "",
            email: "",
            why: ""
          }
        }
      end

      it "re-renders the form with errors and a 422 so Turbo shows them" do
        post "/get-in-touch", params: invalid_params, headers: { "Host" => "lvh.me" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
