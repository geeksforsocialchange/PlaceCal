# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Pages", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe "GET / (home page)" do
    it "returns successful response" do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it "displays site name in title" do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>#{site.name}</title>")
    end

    it "includes og:title meta tag" do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("og:title")
    end

    it "includes og:description meta tag" do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("og:description")
    end

    it "includes og:image meta tag" do
      get root_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("og:image")
    end

    context "with tagline set" do
      before { site.update!(tagline: "Custom tagline for testing") }

      it "uses tagline in description" do
        get root_url(host: "#{site.slug}.lvh.me")
        expect(response.body).to include("Custom tagline for testing")
      end
    end
  end

  describe "GET / (default site)" do
    let!(:default_site) { create(:default_site) }

    it "shows default site home page" do
      get "http://lvh.me"
      expect(response).to be_successful
      expect(response.body).to include("<title>")
    end
  end

  describe "GET /privacy" do
    it "returns successful response" do
      # NOTE: /about doesn't exist, but /privacy does
      get "/privacy", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "site not found" do
    it "handles non-existent site slug" do
      get root_url(host: "nonexistent.lvh.me")
      # Should either 404 or redirect
      expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
    end
  end

  describe "GET /robots.txt" do
    it "returns robots.txt for a site" do
      get "/robots.txt", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
      expect(response.content_type).to include("text/plain")
    end

    it "returns disallow-all robots.txt for admin subdomain" do
      get "/robots.txt", headers: { "Host" => "admin.lvh.me" }
      expect(response).to be_successful
      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Disallow: /")
    end
  end
end
