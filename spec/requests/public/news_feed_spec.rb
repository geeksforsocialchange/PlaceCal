# frozen_string_literal: true

require "rails_helper"

RSpec.describe "News RSS feeds", type: :request do
  let(:site) { create(:site, slug: "feed-site") }
  let(:ward) { create(:riverside_ward) }
  let(:other_ward) { create(:oldtown_ward) }

  # An address partner and a service-area-only partner, both on the site
  let!(:address_partner) { create(:partner, address: create(:address, neighbourhood: ward)) }
  let!(:service_area_partner) do
    create(:mobile_partner,
           address: create(:address, neighbourhood: other_ward),
           service_area_wards: [ward])
  end
  # A partner nowhere near the site
  let!(:outside_partner) { create(:partner, address: create(:address, neighbourhood: other_ward)) }

  let!(:address_article) { create(:article, partners: [address_partner], title: "Address partner post") }
  let!(:service_area_article) { create(:article, partners: [service_area_partner], title: "Service area post") }
  let!(:outside_article) { create(:article, partners: [outside_partner], title: "Outside post") }
  let!(:draft_article) { create(:article, partners: [address_partner], title: "Draft post", is_draft: true) }

  before { site.neighbourhoods << ward }

  def feed_for(response)
    Nokogiri::XML(response.body).tap do |doc|
      expect(doc.errors).to be_empty
    end
  end

  def item_titles(doc)
    doc.xpath("//item/title").map(&:text)
  end

  describe "GET /news.rss on a site" do
    it "returns valid RSS scoped to the site, including service-area partners" do
      get news_index_url(host: "#{site.slug}.lvh.me", format: :rss)

      expect(response).to be_successful
      expect(response.media_type).to eq("application/rss+xml")

      doc = feed_for(response)
      expect(doc.at_xpath("//channel/title").text).to eq(I18n.t("news.feed.title", name: site.name))
      expect(item_titles(doc)).to contain_exactly("Address partner post", "Service area post")
    end

    it "includes item metadata" do
      get news_index_url(host: "#{site.slug}.lvh.me", format: :rss)

      doc = feed_for(response)
      item = doc.xpath("//item").find { |i| i.at_xpath("title").text == "Address partner post" }

      expect(item.at_xpath("link").text).to include("/news/#{address_article.slug}")
      expect(item.at_xpath("pubDate").text).to eq(address_article.published_at.rfc822)
      expect(item.at_xpath("category").text).to eq(address_partner.name)
      expect(item.at_xpath("description").text).to be_present
    end
  end

  describe "GET /news.rss?partner=slug" do
    it "scopes the feed to one partner and titles it accordingly" do
      get news_index_url(host: "#{site.slug}.lvh.me", format: :rss, params: { partner: address_partner.slug })

      doc = feed_for(response)
      expect(doc.at_xpath("//channel/title").text)
        .to eq(I18n.t("news.feed.title_for_partner", name: site.name, partner: address_partner.name))
      expect(item_titles(doc)).to contain_exactly("Address partner post")
    end
  end

  describe "GET /news.rss on the directory" do
    it "includes every published article platform-wide and no drafts" do
      get news_index_url(host: "lvh.me", format: :rss)

      doc = feed_for(response)
      expect(doc.at_xpath("//channel/title").text).to eq(I18n.t("news.feed.title", name: "PlaceCal"))
      expect(item_titles(doc)).to contain_exactly("Address partner post", "Service area post", "Outside post")
    end
  end

  describe "feed discovery on HTML index pages" do
    it "adds a rel=alternate link and a visible RSS link on the site index" do
      get news_index_url(host: "#{site.slug}.lvh.me")

      expect(response.body).to include('rel="alternate" type="application/rss+xml"')
      expect(response.body).to include("/news.rss")
      expect(response.body).to include(I18n.t("news.index.rss"))
    end

    it "adds both on the directory index" do
      get news_index_url(host: "lvh.me")

      expect(response.body).to include('rel="alternate" type="application/rss+xml"')
      expect(response.body).to include(I18n.t("directory.news.index.rss"))
    end
  end
end
