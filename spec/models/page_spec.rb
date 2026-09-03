# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: pages
#
#  id           :bigint           not null, primary key
#  body         :text
#  body_html    :text
#  is_published :boolean          default(FALSE), not null
#  position     :integer          default(0), not null
#  show_in_nav  :boolean          default(FALSE), not null
#  slug         :string           not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  site_id      :bigint           not null
#
# Indexes
#
#  index_pages_on_site_id_and_slug  (site_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#
RSpec.describe Page, type: :model do
  let(:site) { create(:site) }

  describe "validations" do
    it "is valid with a site, title and slug" do
      expect(build(:page, site: site)).to be_valid
    end

    it "requires a title" do
      page = build(:page, site: site, title: nil)
      expect(page).not_to be_valid
      expect(page.errors[:title]).to be_present
    end

    it "requires a slug" do
      page = build(:page, site: site, slug: nil)
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "requires a site" do
      expect(build(:page, site: nil)).not_to be_valid
    end

    it "rejects uppercase and punctuation in the slug" do
      page = build(:page, site: site, slug: "About Us!")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to be_present
    end

    it "accepts lowercase hyphenated slugs" do
      expect(build(:page, site: site, slug: "about-us")).to be_valid
    end

    it "requires the slug to be unique within a site" do
      create(:page, site: site, slug: "about")
      duplicate = build(:page, site: site, slug: "about")
      expect(duplicate).not_to be_valid
    end

    it "allows the same slug on a different site" do
      create(:page, site: site, slug: "about")
      expect(build(:page, site: create(:site), slug: "about")).to be_valid
    end
  end

  describe "reserved slugs" do
    it "derives them from the route set" do
      expect(described_class.reserved_slugs).to include("events", "partners", "news", "users")
    end

    it "includes routes drawn by extension engines" do
      expect(described_class.reserved_slugs).to include("example-theme-proof")
    end

    it "excludes admin-only routes" do
      expect(described_class.reserved_slugs).not_to include("calendars")
    end

    it "rejects a page claiming a core route" do
      page = build(:page, site: site, slug: "events")
      expect(page).not_to be_valid
      expect(page.errors[:slug]).to include("is reserved by PlaceCal and cannot be used for a page")
    end

    it "rejects other core routes too" do
      %w[partners news terms-of-use get-in-touch].each do |slug|
        expect(build(:page, site: site, slug: slug)).not_to be_valid
      end
    end

    # Sites may publish their own privacy copy at the conventional URL (D14).
    it "allows privacy, the one overridable core route" do
      expect(described_class.reserved_slugs).not_to include("privacy")
      expect(build(:page, site: site, slug: "privacy")).to be_valid
    end
  end

  describe "html render cache" do
    it "renders body markdown into body_html on save" do
      page = create(:page, site: site, body: "## Hello\n\nWorld")
      expect(page.body_html).to include("<h2")
      expect(page.body_html).to include("World")
    end

    it "sanitizes dangerous markup" do
      page = create(:page, site: site, body: "<script>alert('x')</script>Safe")
      expect(page.body_html).not_to include("<script")
      expect(page.body_html).to include("Safe")
    end
  end

  describe "scopes" do
    let!(:published_page) { create(:page, site: site, is_published: true) }
    let!(:draft_page) { create(:draft_page, site: site) }
    let!(:nav_page) { create(:page, site: site, is_published: true, show_in_nav: true, position: 2, title: "Beta") }
    let!(:first_nav_page) { create(:page, site: site, is_published: true, show_in_nav: true, position: 1, title: "Alpha") }
    let!(:hidden_nav_page) { create(:draft_page, site: site, show_in_nav: true) }

    it "published returns only published pages" do
      expect(described_class.published).to include(published_page)
      expect(described_class.published).not_to include(draft_page)
    end

    it "in_nav returns published nav pages ordered by position then title" do
      expect(described_class.in_nav.to_a).to eq([first_nav_page, nav_page])
    end

    it "in_nav excludes unpublished nav pages" do
      expect(described_class.in_nav).not_to include(hidden_nav_page)
    end
  end

  describe "associations" do
    it "is destroyed with its site" do
      page = create(:page, site: site)
      expect { site.destroy }.to change(described_class, :count).by(-1)
      expect(described_class.where(id: page.id)).to be_empty
    end

    it "is reachable from the site" do
      page = create(:page, site: site)
      expect(site.reload.pages).to include(page)
    end
  end

  describe "#summary" do
    it "strips markdown and truncates" do
      page = build(:page, site: site, body: "## Heading\n\n#{'word ' * 100}")
      expect(page.summary).not_to include("#")
      expect(page.summary.length).to be <= 160
    end
  end
end
