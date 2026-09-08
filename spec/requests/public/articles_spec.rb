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

    context "with pagination" do
      let!(:partner) { create(:partner, address: address) }

      def create_published_articles(count)
        count.times do |i|
          article = create(:article, is_draft: false, published_at: (count - i).days.ago)
          article.partners << partner
        end
      end

      context "with fewer articles than one page" do
        before { create_published_articles(5) }

        it "shows neither a newer nor an older link" do
          get news_index_url(host: "#{site.slug}.lvh.me")

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css(".articles__pagination-newer")).to be_nil
          expect(doc.at_css(".articles__pagination-older")).to be_nil
        end
      end

      context "with more articles than one page" do
        before { create_published_articles(NewsController::ARTICLES_PER_PAGE + 5) }

        it "shows an older link on the first page, and no newer link" do
          get news_index_url(host: "#{site.slug}.lvh.me")

          doc = Nokogiri::HTML(response.body)
          expect(doc.at_css(".articles__pagination-newer")).to be_nil

          older = doc.at_css(".articles__pagination-older")
          expect(older).to be_present
          expect(older[:href]).to include("offset=#{NewsController::ARTICLES_PER_PAGE}")
        end

        it "shows a newer link back to the bare index on the second page, and no older link" do
          get news_index_url(host: "#{site.slug}.lvh.me", offset: NewsController::ARTICLES_PER_PAGE)

          doc = Nokogiri::HTML(response.body)
          newer = doc.at_css(".articles__pagination-newer")
          expect(newer).to be_present
          expect(newer[:href]).to eq(news_index_path)

          expect(doc.at_css(".articles__pagination-older")).to be_nil
        end
      end

      context "with three full pages" do
        before { create_published_articles((NewsController::ARTICLES_PER_PAGE * 2) + 5) }

        it "shows a newer link with the offset of the previous page" do
          get news_index_url(host: "#{site.slug}.lvh.me", offset: NewsController::ARTICLES_PER_PAGE * 2)

          doc = Nokogiri::HTML(response.body)
          newer = doc.at_css(".articles__pagination-newer")
          expect(newer[:href]).to include("offset=#{NewsController::ARTICLES_PER_PAGE}")
        end
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

    context "with an image credit" do
      let!(:article) do
        create(:article, is_draft: false, image_credit: "Photo by Jane Doe",
                         article_image: fixture_file_upload("good-cat-picture.jpg"))
      end

      it "shows the credit under the image" do
        get news_url(article, host: "#{site.slug}.lvh.me")

        credit = Nokogiri::HTML(response.body).at_css(".article__image-credit")
        expect(credit).to be_present
        expect(credit.text).to eq("Photo by Jane Doe")
      end
    end

    context "without an image" do
      let!(:article) { create(:article, is_draft: false, image_credit: "Photo by Jane Doe") }

      it "does not show a credit" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response.body).not_to include("article__image-credit")
      end
    end

    context "with a pull quote and at least three paragraphs" do
      let!(:article) do
        create(:article, is_draft: false, pull_quote: "This is the pulled-out quote.",
                         body: "Paragraph one.\n\nParagraph two.\n\nParagraph three.\n\nParagraph four.")
      end

      it "renders the pull quote after the third paragraph" do
        get news_url(article, host: "#{site.slug}.lvh.me")

        content = Nokogiri::HTML(response.body).at_css(".article__content")
        paragraphs = content.css("> p")
        expect(paragraphs.map(&:text)).to eq(["Paragraph one.", "Paragraph two.", "Paragraph three.", "Paragraph four."])

        pull_quote_node = content.at_css(".pullquote")
        expect(pull_quote_node).to be_present
        expect(pull_quote_node.text).to include("This is the pulled-out quote.")

        # The quote sits after the third paragraph, before the fourth.
        third_paragraph = paragraphs[2]
        expect(third_paragraph.next_element["class"]).to include("pullquote")
      end
    end

    context "with a pull quote and fewer than three paragraphs" do
      let!(:article) do
        create(:article, is_draft: false, pull_quote: "This is the pulled-out quote.",
                         body: "Paragraph one.\n\nParagraph two.")
      end

      it "appends the pull quote at the end" do
        get news_url(article, host: "#{site.slug}.lvh.me")

        content = Nokogiri::HTML(response.body).at_css(".article__content")
        last_element = content.children.to_a.rfind(&:element?)
        expect(last_element["class"]).to include("pullquote")
      end
    end

    context "without a pull quote" do
      let!(:article) { create(:article, is_draft: false, pull_quote: nil) }

      it "does not render a pull quote" do
        get news_url(article, host: "#{site.slug}.lvh.me")
        expect(response.body).not_to include("pullquote")
      end
    end
  end
end
