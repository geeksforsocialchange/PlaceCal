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
  end
end
