# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id            :bigint           not null, primary key
#  article_image :string
#  body          :text             not null
#  body_html     :string
#  is_draft      :boolean          default(TRUE), not null
#  published_at  :datetime
#  slug          :string
#  title         :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  index_articles_on_author_id     (author_id)
#  index_articles_on_published_at  (published_at)
#  index_articles_on_slug          (slug) UNIQUE
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
    # Visibility follows the partner (issue #3308 §4): an article is visible on
    # a site iff at least one of its partners is on that site per PartnersQuery.
    let(:site_ward) { create(:riverside_ward) }
    let(:other_ward) { create(:oldtown_ward) }
    let(:site) do
      create(:site).tap { |s| create(:sites_neighbourhood, site: s, neighbourhood: site_ward) }
    end
    let(:site_partner) { create(:partner, address: create(:address, neighbourhood: site_ward)) }

    def create_article(partners:, is_draft: false)
      create(:article, partners: partners, is_draft: is_draft)
    end

    it "returns articles from partners whose address is in a site neighbourhood" do
      article = create_article(partners: [site_partner])

      expect(described_class.for_site(site)).to contain_exactly(article)
    end

    it "returns articles from partners with only a service area in a site neighbourhood" do
      # Address is deliberately outside the site; only the service area matches
      partner = create(:mobile_partner,
                       address: create(:address, neighbourhood: other_ward),
                       service_area_wards: [site_ward])
      article = create_article(partners: [partner])

      expect(described_class.for_site(site)).to contain_exactly(article)
    end

    it "excludes articles from partners outside the site's neighbourhoods" do
      partner = create(:partner, address: create(:address, neighbourhood: other_ward))
      create_article(partners: [partner])

      expect(described_class.for_site(site)).to be_empty
    end

    it "excludes draft articles" do
      create_article(partners: [site_partner], is_draft: true)

      expect(described_class.for_site(site)).to be_empty
    end

    it "excludes articles from hidden partners" do
      site_partner.update!(hidden: true, hidden_reason: "spam", hidden_blame_id: create(:root_user).id)
      create_article(partners: [site_partner])

      expect(described_class.for_site(site)).to be_empty
    end

    it "excludes articles with no partners" do
      create(:article)

      expect(described_class.for_site(site)).to be_empty
    end

    it "returns a multi-partner article once" do
      second_partner = create(:partner, address: create(:address, neighbourhood: site_ward))
      article = create_article(partners: [site_partner, second_partner])

      expect(described_class.for_site(site).to_a).to contain_exactly(article)
    end

    it "returns nothing for a site with no neighbourhoods" do
      empty_site = create(:site)
      create_article(partners: [site_partner])

      expect(described_class.for_site(empty_site)).to be_empty
    end

    context "when the site has partnership tags" do
      let(:partnership) { create(:partnership_tag) }

      before { site.tags << partnership }

      it "returns articles from tagged partners in the site's neighbourhoods" do
        site_partner.tags << partnership
        article = create_article(partners: [site_partner])

        expect(described_class.for_site(site)).to contain_exactly(article)
      end

      it "excludes articles from untagged partners even in the site's neighbourhoods" do
        create_article(partners: [site_partner])

        expect(described_class.for_site(site)).to be_empty
      end

      it "ignores article tags for visibility (they are an API curation tool)" do
        article = create(:article)
        article.tags << partnership

        expect(described_class.for_site(site)).to be_empty
      end
    end
  end

  describe "#og_image_path" do
    it "is nil with no article image and no partner image" do
      article = create(:article, partners: [create(:partner)])

      expect(article.og_image_path).to be_nil
    end

    it "falls back to a partner's image" do
      partner = create(:partner, image: Rack::Test::UploadedFile.new("spec/fixtures/files/good-cat-picture.jpg", "image/jpeg"))
      article = create(:article, partners: [partner])

      expect(article.og_image_path).to be_present
    end

    it "prefers the article's own image" do
      article = create(:article,
                       article_image: Rack::Test::UploadedFile.new("spec/fixtures/files/good-cat-picture.jpg", "image/jpeg"))

      expect(article.og_image_path).to eq(article.highres_image)
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
