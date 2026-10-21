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

  describe "www host for a site stored without www" do
    before { serve_hosts("lvh.me", "*.lvh.me", "wwwtest.lvh.me", "www.leedslike.lvh.me") }

    it "redirects to the site's own address, keeping the path" do
      create(:site, slug: "wwwtest", domain: "wwwtest.lvh.me")
      get "/events?period=future", headers: { "Host" => "www.wwwtest.lvh.me" }
      expect(response).to have_http_status(301)
      expect(response).to redirect_to("https://wwwtest.lvh.me/events?period=future")
    end

    it "redirects other methods too" do
      create(:site, slug: "wwwtest", domain: "wwwtest.lvh.me")
      post "/get-in-touch", headers: { "Host" => "www.wwwtest.lvh.me" }
      expect(response).to redirect_to("https://wwwtest.lvh.me/get-in-touch")
    end

    it "leaves a site stored with www alone" do
      create(:site, slug: "leedslike", domain: "www.leedslike.lvh.me")
      get "/", headers: { "Host" => "www.leedslike.lvh.me" }
      expect(response).not_to have_http_status(301)
    end
  end

  describe "slug subdomain of a site with a domain" do
    let(:production_hosts) { ["placecal.org", "*.placecal.org", "www.queerleeds.lgbt", "transdimension.uk", "www.transdimension.uk"] }

    before { serve_hosts(production_hosts) }

    it "redirects a served domain's slug host to the domain, keeping path and query" do
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      get "/events?period=future", headers: { "Host" => "trans-dimension.placecal.org" }
      expect(response).to have_http_status(301)
      expect(response).to redirect_to("https://transdimension.uk/events?period=future")
    end

    it "serves the site on its served domain" do
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      get "/", headers: { "Host" => "transdimension.uk" }
      expect(response).to have_http_status(200)
    end

    it "redirects www of a served domain stored without www" do
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      get "/partners", headers: { "Host" => "www.transdimension.uk" }
      expect(response).to redirect_to("https://transdimension.uk/partners")
    end

    it "serves a site stored with www on that host without redirecting" do
      create(:site, slug: "queerleeds", domain: "www.queerleeds.lgbt")
      get "/", headers: { "Host" => "www.queerleeds.lgbt" }
      expect(response).to have_http_status(200)
    end

    it "does not redirect a plain site's slug host" do
      create(:site, slug: "hulme")
      get "/events", headers: { "Host" => "hulme.placecal.org" }
      expect(response).to have_http_status(200)
    end

    it "does not redirect an external domain's slug host" do
      create(:site, slug: "fruitsaladevents", domain: "fruitsaladevents.co.uk")
      get "/events", headers: { "Host" => "fruitsaladevents.placecal.org" }
      expect(response).to have_http_status(200)
    end

    it "does not redirect where the deploy does not serve the domain, as on staging" do
      serve_hosts("placecal-staging.org", "*.placecal-staging.org")
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      get "/events", headers: { "Host" => "trans-dimension.placecal-staging.org" }
      expect(response).to have_http_status(200)
    end

    it "does not redirect a form post" do
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      post "/get-in-touch", params: { contact_request: { name: "Sam" } }, headers: { "Host" => "trans-dimension.placecal.org" }
      expect(response).not_to have_http_status(301)
    end

    it "leaves the admin subdomain alone" do
      create(:site, slug: "trans-dimension", domain: "transdimension.uk")
      get "/", headers: { "Host" => "admin.placecal.org" }
      expect(response).not_to have_http_status(301)
    end
  end

  describe "GET /news/:title-derived-slug" do
    let(:tag) { create(:category) }
    let(:site) { create(:site).tap { |s| s.tags << tag } }
    let!(:article) do
      create(:article, title: "Introducting G(END)ER SWAP", slug: "gender-swap-2023", is_draft: false, published_at: 1.day.ago).tap do |a|
        a.tags << tag
      end
    end

    it "301s a title-derived slug to the article's canonical slug" do
      get "/news/introducting-g-end-er-swap", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to have_http_status(301)
      expect(response).to redirect_to("/news/gender-swap-2023")
    end

    it "still 404s for unknown slugs" do
      get "/news/no-such-article", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to have_http_status(404)
    end

    it "does not find an article that belongs to another site" do
      other_site = create(:site).tap { |s| s.tags << create(:category) }

      get "/news/introducting-g-end-er-swap", headers: { "Host" => "#{other_site.slug}.lvh.me" }
      expect(response).to have_http_status(404)
    end

    it "never builds an Article, so it cannot load article bodies" do
      instantiated = []
      subscriber = ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*args|
        payload = ActiveSupport::Notifications::Event.new(*args).payload
        instantiated << payload[:class_name] if payload[:record_count].to_i.positive?
      end

      begin
        get "/news/introducting-g-end-er-swap", headers: { "Host" => "#{site.slug}.lvh.me" }
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      expect(response).to have_http_status(301)
      # The fallback plucks id, title and slug rather than loading rows
      # (#3368 WP 3.1), so no Article object is ever built.
      expect(instantiated).not_to include("Article")
    end

    # A scanner walking /news/wp-admin, /news/backup and the rest runs this once
    # per request, so it reads deduplicated rows, capped.
    it "reads a bounded, deduplicated set of rows" do
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        payload = ActiveSupport::Notifications::Event.new(*args).payload
        queries << [payload[:sql], Array(payload[:type_casted_binds])]
      end

      begin
        get "/news/no-such-article", headers: { "Host" => "#{site.slug}.lvh.me" }
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      sql, binds = queries.find { |(query, _binds)| query.include?('"articles"."title"') && query.include?("LIMIT") }
      expect(sql).to include("SELECT DISTINCT")
      expect(binds).to include(NewsController::FALLBACK_SCAN_LIMIT)
    end

    it "301s a title whose accents parameterize away" do
      create(:article, title: "Café Society: crème brûlée", slug: "cafe-night", is_draft: false).tap { |a| a.tags << tag }

      get "/news/cafe-society-creme-brulee", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to redirect_to("/news/cafe-night")
    end

    context "with more published articles than the scan limit" do
      # insert_all keeps 2,001 rows quick. The target comes last by date and by
      # insertion, so it is outside any first page.
      before do
        now = Time.current
        filler = Array.new(NewsController::FALLBACK_SCAN_LIMIT + 1) do |n|
          { title: "Filler article #{n}", slug: "filler-#{n}", body: "Body", is_draft: false,
            published_at: now.to_date, author_id: article.author_id, created_at: now, updated_at: now }
        end
        ids = Article.insert_all(filler, returning: :id).rows.flatten # rubocop:disable Rails/SkipsModelValidations
        ArticleTag.insert_all(ids.map { |id| { article_id: id, tag_id: tag.id } }) # rubocop:disable Rails/SkipsModelValidations

        create(:article, title: "The one we want", slug: "wanted-canonical", is_draft: false).tap do |target|
          target.tags << tag
          target.update!(published_at: 5.years.ago)
        end
      end

      it "still finds a match outside the first page" do
        get "/news/the-one-we-want", headers: { "Host" => "#{site.slug}.lvh.me" }
        expect(response).to have_http_status(301)
        expect(response).to redirect_to("/news/wanted-canonical")
      end
    end

    context "on the nationwide directory" do
      it "redirects to the homepage without querying the articles table" do
        article_queries = []
        instantiated = []

        sql_subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
          payload = ActiveSupport::Notifications::Event.new(*args).payload
          article_queries << payload[:sql] if payload[:sql].to_s.include?("\"articles\"")
        end
        instantiation_subscriber = ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*args|
          payload = ActiveSupport::Notifications::Event.new(*args).payload
          instantiated << payload[:class_name] if payload[:record_count].to_i.positive?
        end

        begin
          get "/news/no-such-article", headers: { "Host" => "lvh.me" }
        ensure
          ActiveSupport::Notifications.unsubscribe(sql_subscriber)
          ActiveSupport::Notifications.unsubscribe(instantiation_subscriber)
        end

        expect(response).to redirect_to("/")
        # The directory has no site to rescue a slug for, so the title-slug
        # fallback must not scan every published article platform-wide (#3368).
        expect(article_queries).to be_empty
        expect(instantiated).not_to include("Article")
      end
    end
  end
end
