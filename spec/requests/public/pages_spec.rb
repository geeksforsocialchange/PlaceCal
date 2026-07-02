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

  describe "GET / (directory)" do
    it "shows the directory home page" do
      get "http://lvh.me"
      expect(response).to be_successful
      expect(response.body).to include("<title>")
    end

    context "with a featured jump-link neighbourhood" do
      # E08000003 is one of the pinned JUMP_NEIGHBOURHOOD_CODES (Manchester)
      let!(:manchester) do
        create(:neighbourhood, name: "Manchester", unit: "district", unit_code_value: "E08000003")
      end

      before { Rails.cache.delete("directory/jump_neighbourhoods") }

      it "links the jump label to the partners directory filtered by that neighbourhood" do
        get "http://lvh.me"

        expect(response).to be_successful
        expect(response.body).to include("/partners?neighbourhood=#{manchester.id}")
        expect(response.body).to include("Manchester")
      end
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
    it "returns successful response" do
      get "/our-story", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end

    it "includes page content" do
      get "/our-story", headers: { "Host" => "lvh.me" }
      expect(response.body).to match(/PlaceCal/i)
    end
  end

  # The legacy informational pages are deleted (#3163); their URLs 301.
  describe "GET /find-placecal" do
    it "redirects to the directory homepage" do
      get "/find-placecal", headers: { "Host" => "lvh.me" }
      expect(response).to redirect_to("/")
    end
  end

  %w[community-groups vcses housing-providers metropolitan-areas
     culture-tourism social-prescribers].each do |audience_slug|
    describe "GET /#{audience_slug}" do
      it "redirects to the join site when it is enabled" do
        get "/#{audience_slug}", headers: { "Host" => "lvh.me" }
        expect(response).to redirect_to("http://join.lvh.me/who-its-for/#{audience_slug}")
      end
    end
  end

  describe "audience pages while the join site is disabled" do
    it "redirects to get-in-touch" do
      Rails.application.config.x.join_site_enabled = false
      get "/community-groups", headers: { "Host" => "lvh.me" }
      expect(response).to redirect_to("/get-in-touch")
    ensure
      Rails.application.config.x.join_site_enabled = true
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
