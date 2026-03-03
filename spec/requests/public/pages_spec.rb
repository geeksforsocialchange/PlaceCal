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
      get "/privacy", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
    end

    it "includes privacy-related content" do
      get "/privacy", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response.body).to match(/privacy/i)
    end
  end

  describe "GET /terms-of-use" do
    it "returns successful response" do
      get "/terms-of-use", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
    end

    it "includes terms content" do
      get "/terms-of-use", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response.body).to match(/terms/i)
    end
  end

  describe "GET /our-story" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/our-story", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end

    it "includes page content" do
      get "/our-story", headers: { "Host" => "lvh.me" }
      expect(response.body).to match(/PlaceCal/i)
    end
  end

  describe "GET /find-placecal" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/find-placecal", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /community-groups" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/community-groups", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end

    it "includes audience content" do
      get "/community-groups", headers: { "Host" => "lvh.me" }
      expect(response.body).to match(/communit/i)
    end
  end

  # Audience pages
  describe "GET /vcses" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/vcses", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /housing-providers" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/housing-providers", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /metropolitan-areas" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/metropolitan-areas", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /culture-tourism" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/culture-tourism", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /social-prescribers" do
    let!(:default_site) { create(:default_site) }

    it "returns successful response" do
      get "/social-prescribers", headers: { "Host" => "lvh.me" }
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
