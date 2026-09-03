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
  end
end
