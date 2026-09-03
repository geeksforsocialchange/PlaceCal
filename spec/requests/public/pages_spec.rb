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

  describe "GET /find-placecal" do
    it "returns successful response" do
      get "/find-placecal", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /community-groups" do
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
    it "returns successful response" do
      get "/vcses", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /housing-providers" do
    it "returns successful response" do
      get "/housing-providers", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /metropolitan-areas" do
    it "returns successful response" do
      get "/metropolitan-areas", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /culture-tourism" do
    it "returns successful response" do
      get "/culture-tourism", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end
  end

  describe "GET /social-prescribers" do
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

  # WP 1.1 (#3368, D5/D14): static per-site content pages served at /:slug.
  context "with a site content page" do
    let(:site) { create(:site, slug: "hulme", url: "https://hulme.lvh.me") }

    describe "GET /:slug" do
      it "renders a published page" do
        create(:page, site: site, slug: "about", title: "About Hulme", body: "## Who we are\n\nA calendar.")

        get "http://hulme.lvh.me/about"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("About Hulme")
        expect(response.body).to include("Who we are")
      end

      it "sets the page title and description" do
        create(:page, site: site, slug: "about", title: "About Hulme", body: "A friendly local calendar.")

        get "http://hulme.lvh.me/about"

        expect(response.body).to include("<title>About Hulme | #{site.name}</title>")
        expect(response.body).to include("A friendly local calendar.")
      end

      it "404s for an unpublished page" do
        create(:draft_page, site: site, slug: "about")

        get "http://hulme.lvh.me/about"

        expect(response).to have_http_status(:not_found)
      end

      it "404s for an unknown slug" do
        get "http://hulme.lvh.me/nothing-here"

        expect(response).to have_http_status(:not_found)
      end

      it "does not serve another site's page" do
        other_site = create(:site, slug: "other", url: "https://other.lvh.me")
        create(:page, site: other_site, slug: "about", title: "About Other")

        get "http://hulme.lvh.me/about"

        expect(response).to have_http_status(:not_found)
      end

      it "404s on the nationwide directory, which has no site" do
        create(:page, site: site, slug: "about", title: "About Hulme")

        get "http://lvh.me/about"

        expect(response).to have_http_status(:not_found)
      end

      it "does not shadow a core route" do
        get "http://hulme.lvh.me/events"

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("About Hulme")
      end
    end

    describe "GET /privacy" do
      it "prefers the site's own published privacy page (D14)" do
        create(:page, site: site, slug: "privacy", title: "Hulme Privacy", body: "We keep your data safe.")

        get "http://hulme.lvh.me/privacy"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Hulme Privacy")
        expect(response.body).to include("We keep your data safe.")
      end

      it "falls back to the core privacy copy when there is no page" do
        get "http://hulme.lvh.me/privacy"

        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/privacy/i)
      end

      it "falls back when the site's privacy page is a draft" do
        create(:draft_page, site: site, slug: "privacy", title: "Hulme Privacy")

        get "http://hulme.lvh.me/privacy"

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Hulme Privacy")
      end
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

RSpec.describe "Site page wrapper", type: :request do
  it "carries the page slug as a class and data attribute for themes" do
    ward = create(:riverside_ward)
    site = create(:site, slug: "wrap", url: "https://wrap.lvh.me")
    site.neighbourhoods << ward
    create(:page, site: site, slug: "about", title: "About", body: "Hello", is_published: true)
    get "http://wrap.lvh.me/about"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("page page--about")
    expect(response.body).to include('data-page-slug="about"')
  end
end
