# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Articles (News)", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }
  let(:address) { create(:address, neighbourhood: ward) }
  let!(:author) { create(:root_user, first_name: "Alpha", last_name: "Beta") }

  before do
    site.neighbourhoods << ward
  end

  describe "GET /news (index)" do
    context "with articles linked to partners" do
      let!(:article) { create(:article, is_draft: false) }
      let!(:partner1) { create(:partner, address: address) }
      let!(:partner2) { create(:partner, address: address) }

      before do
        article.partners << partner1
        article.partners << partner2
      end

      it "shows partner links" do
        get news_index_url(host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include(partner1.name)
        expect(response.body).to include(partner2.name)
      end
    end

    context "with articles not linked to partners" do
      let!(:article) { create(:article, is_draft: false) }

      it "does not show partner link component" do
        get news_index_url(host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).not_to include("articles__partners")
      end
    end
  end

  describe "GET /news?partner=slug (partner filter)" do
    let!(:partner1) { create(:partner, address: address) }
    let!(:partner2) { create(:partner, address: address) }
    let!(:article1) { create(:article, partners: [partner1], title: "Post from partner one") }
    let!(:article2) { create(:article, partners: [partner2], title: "Post from partner two") }

    it "shows only the filtered partner's articles" do
      get news_index_url(host: "#{site.slug}.lvh.me", params: { partner: partner1.slug })

      expect(response).to be_successful
      expect(response.body).to include("Post from partner one")
      expect(response.body).not_to include("Post from partner two")
    end

    it "titles the page for the partner" do
      get news_index_url(host: "#{site.slug}.lvh.me", params: { partner: partner1.slug })

      expect(response.body).to include(
        CGI.escapeHTML(I18n.t("news.index.title_for_partner", partner: partner1.name))
      )
    end
  end

  describe "site navigation News link" do
    let!(:partner) { create(:partner, address: address) }

    it "appears when the site's partners have published news" do
      create(:article, partners: [partner])

      get partners_url(host: "#{site.slug}.lvh.me")

      expect(response.body).to include('href="/news"')
    end

    it "does not appear when the site has no news" do
      get partners_url(host: "#{site.slug}.lvh.me")

      expect(response.body).not_to include('href="/news"')
    end
  end

  describe "partner page latest news section" do
    let!(:partner) { create(:partner, address: address) }

    it "shows up to 3 recent posts with a more link when there are more" do
      4.times { |n| create(:article, partners: [partner], title: "Partner post #{n}", published_at: n.days.ago) }

      get partner_url(partner, host: "#{site.slug}.lvh.me")

      expect(response).to be_successful
      expect(response.body).to include(I18n.t("news.partner_section.title"))
      expect(response.body).to include("Partner post 0")
      expect(response.body).to include("Partner post 2")
      expect(response.body).not_to include("Partner post 3")
      expect(response.body).to include(
        CGI.escapeHTML(I18n.t("news.partner_section.more", partner: partner.name))
      )
    end

    it "renders no news section when the partner has no posts" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")

      expect(response.body).not_to include(I18n.t("news.partner_section.title"))
    end

    it "shows the section on the directory partner page" do
      create(:article, partners: [partner], title: "Directory partner post")

      get partner_url(partner, host: "lvh.me")

      expect(response).to be_successful
      expect(response.body).to include(I18n.t("directory.partners.show.latest_news"))
      expect(response.body).to include("Directory partner post")
    end
  end

  describe "GET /news on the directory (placecal.org)" do
    let!(:partner) { create(:partner, address: address) }
    let!(:article) { create(:article, partners: [partner], title: "Platform-wide post") }
    let!(:draft) { create(:article, partners: [partner], title: "Unpublished post", is_draft: true) }

    it "renders the platform-wide news index" do
      get news_index_url(host: "lvh.me")

      expect(response).to be_successful
      expect(response.body).to include(I18n.t("directory.news.index.hero_title"))
      expect(response.body).to include("Platform-wide post")
      expect(response.body).not_to include("Unpublished post")
    end

    it "shows the partner name on the card" do
      get news_index_url(host: "lvh.me")

      expect(response.body).to include(partner.name)
    end

    it "filters by partner" do
      other = create(:partner, address: address)
      create(:article, partners: [other], title: "Someone else entirely")

      get news_index_url(host: "lvh.me", params: { partner: partner.slug })

      expect(response.body).to include("Platform-wide post")
      expect(response.body).not_to include("Someone else entirely")
    end

    it "renders the article show page" do
      get news_url(article, host: "lvh.me")

      expect(response).to be_successful
      expect(response.body).to include("Platform-wide post")
      expect(response.body).to include(I18n.t("directory.news.show.back"))
    end

    it "shows the empty state with no articles" do
      Article.destroy_all

      get news_index_url(host: "lvh.me")

      expect(response).to be_successful
      expect(response.body).to include(I18n.t("directory.news.index.empty"))
    end
  end

  describe "article show meta tags" do
    let!(:partner) { create(:partner, address: address) }
    let!(:article) do
      create(:article, partners: [partner], title: "Meta post", body: "A body worth describing in meta tags")
    end

    it "sets a meta description from the article body" do
      get news_url(article, host: "#{site.slug}.lvh.me")

      expect(response.body).to include('property="og:description" content="A body worth describing in meta tags"')
    end
  end

  describe "GET /news/:id (show)" do
    context "with articles linked to partners" do
      let!(:article) { create(:article, is_draft: false) }
      let!(:partner1) { create(:partner, address: address) }
      let!(:partner2) { create(:partner, address: address) }

      before do
        article.partners << partner1
        article.partners << partner2
      end

      it "shows partner links" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include(partner1.name)
        expect(response.body).to include(partner2.name)
      end
    end

    context "with articles not linked to partners" do
      let!(:article) { create(:article, is_draft: false) }

      it "does not show partner link component" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).not_to include("article__partners")
      end
    end

    context "with author name" do
      let!(:article) { create(:article, is_draft: false, author: author) }

      it "shows author name" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).to include("Alpha Beta")
      end
    end

    context "with author missing name" do
      let!(:no_name_author) { create(:user, role: "root", first_name: "", last_name: "") }
      let!(:article) { create(:article, is_draft: false, author: no_name_author) }

      it "does not show author component" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response).to be_successful
        expect(response.body).not_to include("article__author")
      end
    end
  end
end
