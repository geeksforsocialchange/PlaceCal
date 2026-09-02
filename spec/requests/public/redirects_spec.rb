# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Redirects", type: :request do
  describe "Legacy aliases" do
    describe "GET /join-us" do
      it "redirects to /get-in-touch with 301 status" do
        get "/join-us", headers: { "Host" => "lvh.me" }
        expect(response).to have_http_status(301)
        expect(response).to redirect_to("/get-in-touch")
      end

      it "redirects on a site host" do
        site = create(:site)
        get "/join-us", headers: { "Host" => "#{site.slug}.lvh.me" }
        expect(response).to have_http_status(301)
        expect(response).to redirect_to("/get-in-touch")
      end
    end
  end
end
