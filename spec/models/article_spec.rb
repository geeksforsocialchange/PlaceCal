# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id            :bigint           not null, primary key
#  article_image :string
#  body          :text             not null
#  body_html     :string
#  image_credit  :string
#  is_draft      :boolean          default(TRUE), not null
#  published_at  :date
#  pull_quote    :text
#  slug          :string
#  title         :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  index_articles_on_author_id  (author_id)
#  index_articles_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#
require "rails_helper"

RSpec.describe Article do
  let(:article) { create(:article) }
  let(:article_draft) { create(:article_draft) }

  describe "validations" do
    it "is valid" do
      expect(article).to be_valid
    end

    it "requires title to be present" do
      article.title = ""
      expect(article).not_to be_valid
    end

    it "requires body to be present" do
      article.body = ""
      expect(article).not_to be_valid
    end
  end

  describe "published_at" do
    it "updates correctly when is_draft is set" do
      expect(article_draft.published_at).to be_nil

      article_draft.is_draft = false
      article_draft.save!

      expect(article_draft.published_at).to be_present
    end
  end

  describe ".with_tags" do
    it "finds articles tagged with tag" do
      user = create(:user)
      tag = create(:tag)

      # articles without tag
      4.times do |n|
        described_class.create!(
          title: "Article title no. #{n}",
          body: "lorem ipsum ...",
          author: user
        )
      end

      # with tags
      2.times do |n|
        article = described_class.create!(
          title: "Article title no. #{n}",
          body: "lorem ipsum ...",
          author: user
        )
        article.tags << tag
      end

      found = described_class.with_tags(tag.id)
      expect(found.count).to eq(2)
    end
  end

  describe ".with_partner_tag" do
    it "finds articles from partners with a given tag" do
      user = create(:user)
      tag = create(:tag)
      partner = create(:partner)
      partner.tags << tag

      # articles not by partner (no tag)
      3.times do |n|
        described_class.create!(
          title: "Article title no. #{n}",
          body: "lorem ipsum ...",
          author: user
        )
      end

      # articles by tagged partner
      5.times do |n|
        article = described_class.create!(
          title: "Article title no. #{n}",
          body: "lorem ipsum ...",
          author: user
        )
        article.partners << partner
      end

      found = described_class.with_partner_tag(tag.id)
      expect(found.length).to eq(5)
    end
  end

  describe ".for_site" do
    let(:neighbourhood_1) { create(:riverside_ward) }
    let(:neighbourhood_2) { create(:oldtown_ward) }
    let(:author) { create(:root) }

    it "returns articles for site (via neighbourhood)" do
      site = create(:site)
      site.neighbourhoods << neighbourhood_1
      site.neighbourhoods << neighbourhood_2

      partner_1 = create(:partner, address: create(:address, neighbourhood: neighbourhood_1))
      partner_2 = create(:partner, address: create(:address, neighbourhood: neighbourhood_2))

      # from first partner
      2.times do |n|
        partner_1.articles.create!(
          title: "#{n} Article from Partner 1",
          is_draft: false,
          body: "lorem ipsum dorem ditsum",
          author: author
        )
      end

      # from second partner
      3.times do |n|
        partner_2.articles.create!(
          title: "#{n} Article from Partner 2",
          is_draft: false,
          body: "lorem ipsum dorem ditsum",
          author: author
        )
      end

      found = described_class.for_site(site).select(:id)
      expect(found.count).to eq(5)
    end

    it "returns articles with site tags applied" do
      tag = create(:tag)

      site = create(:site)
      site.tags << tag
      site.validate!

      3.times do |n|
        article = described_class.create!(
          title: "#{n} Article with tag",
          is_draft: false,
          body: "lorem ipsum dorem ditsum",
          author: author
        )
        article.tags << tag
        article.validate!
      end

      found = described_class.for_site(site)
      expect(found.count).to eq(3)
    end

    it "finds articles by both neighbourhood and tag" do
      site = create(:site)

      site.neighbourhoods << neighbourhood_1

      partner = create(:partner, address: create(:address, neighbourhood: neighbourhood_1))

      3.times do |n|
        partner.articles.create!(
          title: "#{n} Article from Partner by neighbourhood",
          is_draft: false,
          body: "lorem ipsum dorem ditsum",
          author: author
        )
      end

      tag = create(:tag)
      site.tags << tag

      5.times do |n|
        article = described_class.create!(
          title: "#{n} Article with tag",
          is_draft: false,
          body: "lorem ipsum dorem ditsum",
          author: author
        )
        article.tags << tag
      end

      found = described_class.for_site(site).select(:id)
      expect(found.count).to eq(8)
    end
  end

  describe "publish order neighbours" do
    let(:author) { create(:root) }
    let!(:older) { article_published(Date.new(2026, 1, 1)) }
    let!(:same_day_first) { article_published(Date.new(2026, 2, 1)) }
    let!(:same_day_second) { article_published(Date.new(2026, 2, 1)) }
    let!(:undated) { article_published(nil) }

    # update_published_at overwrites published_at on create, so set it afterwards.
    def article_published(on)
      described_class.create!(title: "Article", body: "Body", is_draft: false, author: author).tap do |article|
        article.update!(published_at: on)
      end
    end

    it "walks the same order as by_publish_date, ties and undated articles included" do
      listed = described_class.by_publish_date.to_a
      expect(listed).to eq([undated, same_day_second, same_day_first, older])

      listed.each_with_index do |article, index|
        expect(described_class.listed_before(article).first).to eq(index.positive? ? listed[index - 1] : nil)
        expect(described_class.listed_after(article).first).to eq(listed[index + 1])
      end
    end
  end

  describe ".title_slug_candidates" do
    let(:author) { create(:root) }

    titles = [
      "Introducting G(END)ER SWAP",
      "Café Society: crème brûlée night",
      "Ærø & Straße",
      "snake_case  -- spaced - hyphens",
      "100% fun!",
      "Ünïcödé 🎉 party",
      "Ꭰ Cherokee only ᏣᎳᎩ title"
    ]

    titles.each do |title|
      it "finds #{title.inspect} by its own parameterized slug" do
        article = described_class.create!(title: title, body: "Body", is_draft: false, author: author)
        described_class.create!(title: "Unrelated headline", body: "Body", is_draft: false, author: author)

        found = described_class.title_slug_candidates(title.parameterize)

        expect(found).to include(article)
        expect(found.map(&:title)).not_to include("Unrelated headline")
      end
    end
  end

  describe "body_html" do
    it "is rendered from body" do
      art = create(:article)
      art.body = "A body of text about something"
      art.save!
      expect(art.body_html).to be_present
    end
  end
end
