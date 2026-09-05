# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Sitemaps", type: :request do
  let!(:local_site) do
    create(:site, slug: "mossley", is_published: true, url: "https://mossley.placecal.org/",
                  contact_email: "hello@mossley.example.org")
  end

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
      let!(:upcoming_event) { create(:event, dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour) }
      let!(:past_event) { create(:event, dtstart: 1.week.ago, dtend: 1.week.ago + 1.hour) }
      let!(:ongoing_event) { create(:event, dtstart: 1.day.ago, dtend: 1.day.from_now) }

      it "includes upcoming events" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://placecal.org/events/#{upcoming_event.id}")
      end

      # Past event pages are noindexed (see Views::Events::Show), so listing
      # them would trigger "submitted URL marked noindex" warnings.
      it "excludes past events" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response.body).not_to include("events/#{past_event.id}")
      end

      it "includes multi-day events still running" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response.body).to include("events/#{ongoing_event.id}")
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
    let(:host) { "mossley.lvh.me" }

    let!(:site_neighbourhood) { create(:neighbourhood) }
    let!(:other_neighbourhood) { create(:neighbourhood) }

    let!(:site_partner) do
      create(:partner, slug: "site-partner", address: create(:address, neighbourhood: site_neighbourhood))
    end
    let!(:other_partner) do
      create(:partner, slug: "other-site-partner", address: create(:address, neighbourhood: other_neighbourhood))
    end

    let!(:site_event) do
      create(:event, organiser: site_partner, dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour)
    end
    let!(:other_event) do
      create(:event, organiser: other_partner, dtstart: 1.week.from_now, dtend: 1.week.from_now + 1.hour)
    end

    let!(:site_article) do
      article = create(:article, slug: "site-news", is_draft: false)
      create(:article_partner, article: article, partner: site_partner)
      article
    end

    before do
      create(:sites_neighbourhood, site: local_site, neighbourhood: site_neighbourhood)
      create(:site, slug: "other", is_published: true, url: "https://other.placecal.org/").tap do |other|
        create(:sites_neighbourhood, site: other, neighbourhood: other_neighbourhood)
      end
    end

    describe "GET /sitemap.xml" do
      it "lists the site's own sections under the site's URL" do
        get "/sitemap.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.content_type).to include("xml")
        %w[partners events pages].each do |section|
          expect(response.body).to include("https://mossley.placecal.org/sitemap/#{section}.xml")
        end
      end

      it "does not advertise the directory or the partnerships section" do
        get "/sitemap.xml", headers: { "Host" => host }
        expect(response.body).not_to include("https://placecal.org/")
        expect(response.body).not_to include("partnerships")
      end

      it "varies on Host, since the same path serves a different sitemap per site" do
        get "/sitemap.xml", headers: { "Host" => host }

        expect(response.headers["Cache-Control"]).to include("public")
        expect(response.headers["Vary"]).to include("Host")
      end
    end

    describe "GET /sitemap/partners.xml" do
      it "includes the site's partners with a lastmod" do
        get "/sitemap/partners.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://mossley.placecal.org/partners/site-partner")
        expect(response.body).to match(%r{<lastmod>\d{4}-\d{2}-\d{2}</lastmod>})
      end

      it "excludes partners belonging to another site" do
        get "/sitemap/partners.xml", headers: { "Host" => host }
        expect(response.body).not_to include("other-site-partner")
      end
    end

    describe "GET /sitemap/events.xml" do
      it "includes the site's upcoming events" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("https://mossley.placecal.org/events/#{site_event.id}")
      end

      it "excludes events belonging to another site" do
        get "/sitemap/events.xml", headers: { "Host" => host }
        expect(response.body).not_to include("events/#{other_event.id}")
      end
    end

    describe "GET /sitemap/pages.xml" do
      it "includes the site's static pages and news" do
        get "/sitemap/pages.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).to include("<loc>https://mossley.placecal.org</loc>")
        expect(response.body).to include("https://mossley.placecal.org/partners")
        expect(response.body).to include("https://mossley.placecal.org/events")
        expect(response.body).to include("https://mossley.placecal.org/privacy")
        expect(response.body).to include("https://mossley.placecal.org/get-in-touch")
        expect(response.body).to include("https://mossley.placecal.org/news/site-news")
      end

      it "does not link to the directory" do
        get "/sitemap/pages.xml", headers: { "Host" => host }
        expect(response.body).not_to include("https://placecal.org/")
      end

      it "lists /privacy once" do
        get "/sitemap/pages.xml", headers: { "Host" => host }

        expect(response.body.scan("<loc>https://mossley.placecal.org/privacy</loc>").size).to eq(1)
      end

      # Mirrors SiteNavigation#join_navigation: no enquiries address, no Join.
      it "omits /get-in-touch for a site that takes no enquiries" do
        local_site.update!(contact_email: nil)

        get "/sitemap/pages.xml", headers: { "Host" => host }

        expect(response.body).not_to include("https://mossley.placecal.org/get-in-touch")
      end
    end

    describe "GET /sitemap/partnerships.xml" do
      it "is empty (partnerships are a directory concept)" do
        get "/sitemap/partnerships.xml", headers: { "Host" => host }
        expect(response).to be_successful
        expect(response.body).not_to include("<url>")
      end
    end
  end

  describe "robots.txt" do
    it "advertises the site's own sitemap for published sites" do
      get "/robots.txt", headers: { "Host" => "mossley.lvh.me" }
      expect(response.body).to include("Sitemap: https://mossley.placecal.org/sitemap.xml")
      expect(response.body).not_to include("Sitemap: https://placecal.org/sitemap.xml")
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
