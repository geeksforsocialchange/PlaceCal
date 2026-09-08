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

      it "renders the byline as links, with no trailing full stop" do
        get news_index_url(host: "#{site.slug}.lvh.me")

        byline = Nokogiri::HTML(response.body).at_css(".articles__partners")

        expect(byline.css("a").map(&:text)).to contain_exactly(partner1.name, partner2.name)
        expect(byline.text.strip).not_to end_with(".")
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

    context "with the back link" do
      let!(:article) { create(:article, is_draft: false) }

      # `news_path` with no argument takes the id from the current request, so
      # the back link used to point at the article the reader was already on.
      it "points at the news index, not at the article itself" do
        get news_url(article, host: "#{site.slug}.lvh.me")

        back = Nokogiri::HTML(response.body).at_css(".article__back a")

        expect(back).to be_present
        expect(back[:href]).to eq(news_index_path)
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

    # Hero back link (#3368): "All news" above the article page hero.
    context "with the hero back link" do
      let!(:article) { create(:article, is_draft: false) }

      it "points at the news index" do
        get news_url(article, host: "#{site.slug}.lvh.me")

        back = Nokogiri::HTML(response.body).at_css("a.hero__back")
        expect(back.text).to eq(I18n.t("news.show.back_to_index"))
        expect(back[:href]).to eq(news_index_path)
      end
    end

    # Page actions row (Components::PageActions, #3368): previous/next by
    # publish date within this site, plus back to the index. NewsController
    # computes the neighbours with Article.for_site, which calls `.distinct`
    # (see the model) - this runs for real against Postgres, which is the
    # only thing that can actually catch a DISTINCT/ORDER BY mismatch.
    context "with the page actions row" do
      # Article.for_site only picks up articles linked (by partner address or
      # tag) to this site, same as the "with articles linked to partners"
      # context above - a bare article factory instance is invisible to it.
      let(:site_partner) { create(:partner, address: create(:address, neighbourhood: ward)) }
      let!(:oldest) { published_article(3.days.ago) }
      let!(:middle) { published_article(2.days.ago) }
      let!(:newest) { published_article(1.day.ago) }

      # Article#update_published_at stamps published_at to `now` whenever
      # is_draft changes on save - which fires on every create, since the
      # column defaults to true - so a published_at given at create time is
      # silently overwritten. Setting it in a second update (with is_draft
      # unchanged) is the only way to actually control it.
      def published_article(published_at)
        article = create(:article, is_draft: false, partners: [site_partner])
        article.update!(published_at: published_at)
        article
      end

      def page_action_links
        Nokogiri::HTML(response.body).css("nav.page-actions a.page-actions__link")
      end

      it "links to the newer and older articles either side of the middle one" do
        get news_url(middle, host: "#{site.slug}.lvh.me")

        expect(response).to be_successful
        links = page_action_links
        expect(links.map(&:text)).to contain_exactly(
          I18n.t("news.show.previous"), I18n.t("news.show.next"), I18n.t("news.show.go_back")
        )
        expect(links.find { |a| a.text == I18n.t("news.show.previous") }[:href]).to eq(news_path(newest))
        expect(links.find { |a| a.text == I18n.t("news.show.next") }[:href]).to eq(news_path(oldest))
        expect(links.find { |a| a.text == I18n.t("news.show.go_back") }[:href]).to eq(news_index_path)
      end

      it "omits the previous link for the newest article" do
        get news_url(newest, host: "#{site.slug}.lvh.me")

        expect(page_action_links.map(&:text)).not_to include(I18n.t("news.show.previous"))
        expect(page_action_links.map(&:text)).to include(I18n.t("news.show.next"))
      end

      it "omits the next link for the oldest article" do
        get news_url(oldest, host: "#{site.slug}.lvh.me")

        expect(page_action_links.map(&:text)).not_to include(I18n.t("news.show.next"))
        expect(page_action_links.map(&:text)).to include(I18n.t("news.show.previous"))
      end
    end
  end
end
