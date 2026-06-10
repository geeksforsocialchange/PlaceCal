# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Sitemaps", type: :request do
  let!(:local_site) { create(:site, slug: "mossley", is_published: true, url: "https://mossley.placecal.org/") }

  describe "on the apex (directory)" do
    let(:host) { "lvh.me" }

    describe "GET /sitemap.xml" do
      it "returns a sitemap index with sub-sitemaps" do
        get "/sitemap.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.content_type).to include("xml")
        expect(response.body).to include("sitemapindex")
        %w[partners events partnerships pages].each do |section|
          expect(response.body).to include("https://placecal.org/sitemap/#{section}.xml")
        end
      end
    end

    describe "GET /sitemap/partners.xml" do
      let!(:partner) { create(:partner, slug: "test-partner") }

      it "includes visible partners" do
        get "/sitemap/partners.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://placecal.org/partners/test-partner")
      end

      it "excludes hidden partners" do
        admin = create(:root)
        partner.update!(hidden: true, hidden_reason: "test", hidden_blame_id: admin.id)
        get "/sitemap/partners.xml", headers: { "Host" => host }
        expect(response.body).not_to include("test-partner")
      end
    end

    describe "GET /sitemap/events.xml" do
      let!(:recent_event) { create(:event, dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour) }
      let!(:old_event) { create(:event, dtstart: 6.months.ago, dtend: 6.months.ago + 1.hour) }

      it "includes recent events" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://placecal.org/events/#{recent_event.id}")
      end

      it "excludes events older than 3 months" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response.body).not_to include("events/#{old_event.id}")
      end
    end

    describe "GET /sitemap/partnerships.xml" do
      it "includes partnerships index and published sites" do
        get "/sitemap/partnerships.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://placecal.org/partnerships")
        expect(response.body).to include("https://placecal.org/partnerships/mossley")
        expect(response.body).to include("https://mossley.placecal.org")
      end
    end

    describe "GET /sitemap/pages.xml" do
      it "includes static pages" do
        get "/sitemap/pages.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://placecal.org")
        expect(response.body).to include("https://placecal.org/partners")
        expect(response.body).to include("https://placecal.org/events")
        expect(response.body).to include("https://placecal.org/privacy")
        expect(response.body).not_to include("find-placecal")
      end
    end
  end

  describe "on a local site" do
    it "returns 404" do
      get "/sitemap.xml", headers: { "Host" => "mossley.lvh.me" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "robots.txt" do
    it "includes sitemap directive for published sites" do
      get "/robots.txt", headers: { "Host" => "mossley.lvh.me" }
      expect(response.body).to include("Sitemap: https://placecal.org/sitemap.xml")
    end

    it "serves a crawlable robots.txt with sitemap on the apex" do
      get "/robots.txt", headers: { "Host" => "lvh.me" }
      expect(response.body).to include("Sitemap: https://placecal.org/sitemap.xml")
      expect(response.body).not_to include("Disallow: /\n")
    end

    it "disallows everything on the admin subdomain" do
      get "/robots.txt", headers: { "Host" => "admin.lvh.me" }
      expect(response.body).to include("Disallow: /")
    end
  end
end
