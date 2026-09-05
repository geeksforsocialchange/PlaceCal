# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
#
#  id                :bigint           not null, primary key
#  badge_zoom_level  :string
#  contact_email     :string
#  description       :text
#  description_html  :string
#  events_count      :integer          default(0), not null
#  footer_logo       :string
#  hero_alttext      :string
#  hero_image        :string
#  hero_image_credit :string
#  hero_text         :string
#  is_published      :boolean          default(FALSE), not null
#  logo              :string
#  name              :string           not null
#  partners_count    :integer          default(0), not null
#  place_name        :string
#  slug              :string           not null
#  tagline           :string
#  theme             :string           default("pink")
#  url               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_admin_id     :bigint
#
# Indexes
#
#  index_sites_is_published       (is_published)
#  index_sites_on_events_count    (events_count)
#  index_sites_on_partners_count  (partners_count)
#  index_sites_slug               (slug) UNIQUE
#  index_sites_url                (url)
#
# Foreign Keys
#
#  fk_rails_...  (site_admin_id => users.id)
#
require "rails_helper"

RSpec.describe Site, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:sites_neighbourhoods).dependent(:destroy) }
    it { is_expected.to have_many(:neighbourhoods).through(:sites_neighbourhoods) }
    it { is_expected.to have_many(:sites_tag).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:sites_tag) }
    it { is_expected.to have_and_belong_to_many(:supporters) }
    it { is_expected.to belong_to(:site_admin).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    describe "contact_email" do
      it "is valid when blank" do
        expect(build(:site, contact_email: nil)).to be_valid
        expect(build(:site, contact_email: "")).to be_valid
      end

      it "is valid with a well-formed address" do
        expect(build(:site, contact_email: "hello@example.org")).to be_valid
      end

      it "is invalid with a malformed address" do
        site = build(:site, contact_email: "not-an-email")
        expect(site).not_to be_valid
        expect(site.errors[:contact_email]).to be_present
      end
    end

    # NOTE: slug presence is enforced at the model and database level, but a
    # blank slug is auto-generated from the name before validation (see
    # #should_generate_new_friendly_id? and the "FriendlyId" specs below), so
    # validate_presence_of(:slug) cannot be asserted via shoulda-matchers.

    # NOTE: FriendlyId handles slug uniqueness at the database level
    # No explicit validates_uniqueness_of on slug in the model
  end

  describe "#join_recipient" do
    it "returns the site's own contact email when set" do
      site = build(:site, contact_email: "hello@example.org")
      expect(site.join_recipient).to eq("hello@example.org")
    end

    it "falls back to the default recipient when blank" do
      expect(build(:site, contact_email: nil).join_recipient).to eq(Join::DEFAULT_RECIPIENT)
      expect(build(:site, contact_email: "").join_recipient).to eq(Join::DEFAULT_RECIPIENT)
    end
  end

  describe "factories" do
    it "creates a valid site" do
      site = build(:site)
      expect(site).to be_valid
    end

    it "creates a millbrook site" do
      site = create(:millbrook_site)
      expect(site.name).to eq("Millbrook Community Calendar")
    end

    it "creates an ashdale site" do
      site = create(:ashdale_site)
      expect(site.name).to eq("Ashdale Connect")
    end
  end

  describe "FriendlyId" do
    it "uses slug for URL" do
      site = create(:site, name: "Test Site", slug: "test-site")
      expect(site.to_param).to eq("test-site")
    end

    it "auto-populates the slug from the name on create when slug is left blank" do
      site = create(:site, name: "My Brand New Site", slug: "")
      expect(site.slug).to eq("my-brand-new-site")
    end

    it "auto-populates the slug from the name on create when no slug is given" do
      site = build(:site, name: "Another New Site")
      site.slug = nil
      site.save!
      expect(site.slug).to eq("another-new-site")
    end

    it "keeps an explicitly provided slug on create" do
      site = create(:site, name: "Named Site", slug: "my-custom-slug")
      expect(site.slug).to eq("my-custom-slug")
    end

    describe "#should_generate_new_friendly_id?" do
      it "is true when the slug is blank" do
        expect(build(:site, slug: "").should_generate_new_friendly_id?).to be(true)
      end

      it "is false when the slug is present" do
        expect(build(:site, slug: "present").should_generate_new_friendly_id?).to be(false)
      end
    end
  end

  describe "#directory_url" do
    it "returns the url when present" do
      site = build(:site, url: "https://example.org")
      expect(site.directory_url).to eq("https://example.org")
    end

    it "falls back to the placecal.org subdomain when the url is blank" do
      site = build(:site, slug: "manchester", url: "")
      expect(site.directory_url).to eq("https://manchester.placecal.org")
    end
  end

  describe "#display_url" do
    it "strips the scheme and trailing slash" do
      site = build(:site, url: "https://example.org/")
      expect(site.display_url).to eq("example.org")
    end
  end

  describe "#owned_neighbourhood_ids" do
    let(:site) { create(:site) }
    let(:ward) { create(:riverside_ward) }

    before do
      site.neighbourhoods << ward
    end

    it "returns IDs of all owned neighbourhoods including descendants" do
      ids = site.owned_neighbourhood_ids
      expect(ids).to include(ward.id)
    end
  end

  describe "theming" do
    it "has theme attribute" do
      site = build(:site, theme: "pink")
      expect(site.theme).to eq("pink")
    end

    it "defaults to pink" do
      expect(described_class.new.theme).to eq("pink")
    end

    it "accepts every theme registered in the extension registry" do
      PlaceCal::Extensions.theme_names.each do |name|
        site = build(:site, theme: name)
        expect(site).to be_valid, "expected theme #{name} to be valid: #{site.errors[:theme].inspect}"
      end
    end

    it "rejects a theme that is not registered" do
      site = build(:site, theme: "nope")
      expect(site).not_to be_valid
      expect(site.errors[:theme]).to be_present
    end

    it "accepts a theme registered by an extension", :theme_registry do
      PlaceCal::Extensions.register_theme(:late_arrival)
      expect(build(:site, theme: "late_arrival")).to be_valid
    end

    it "allows a blank theme, as the enumerize-era column did" do
      site = create(:site, theme: nil)
      expect(site).to be_valid
      expect(site.reload.theme).to be_nil
      expect(site.stylesheet_link).to be_nil
    end

    it "allows an empty string theme" do
      expect(build(:site, theme: "")).to be_valid
    end

    describe "#stylesheet_link" do
      it "returns the core theme stylesheet" do
        %w[pink orange green blue].each do |name|
          expect(build(:site, theme: name).stylesheet_link).to eq("themes/#{name}")
        end
      end

      it "returns nil for a custom theme with no per-site stylesheet" do
        expect(build(:site, theme: "custom", slug: "nosuchsite").stylesheet_link).to be_nil
      end

      it "returns nil when the theme is not registered" do
        expect(build(:site, theme: "nope").stylesheet_link).to be_nil
      end

      it "returns nil and logs when the theme's stylesheet is missing from the pipeline", :theme_registry do
        PlaceCal::Extensions.register_theme(:ghost) { |theme| theme.stylesheet "ghost/theme" }
        allow(Rails.logger).to receive(:warn)

        expect(build(:site, theme: "ghost").stylesheet_link).to be_nil
        expect(Rails.logger).to have_received(:warn).with(%r{ghost/theme\.css})
      end
    end
  end

  describe "configuration" do
    it "has badge_zoom_level attribute" do
      site = build(:site, badge_zoom_level: "district")
      expect(site.badge_zoom_level).to eq("district")
    end

    it "has default_neighbourhood attribute" do
      ward = create(:riverside_ward)
      site = build(:site, primary_neighbourhood: ward)
      expect(site.primary_neighbourhood).to eq(ward)
    end
  end

  describe "#events_this_week" do
    let(:neighbourhood) { create(:neighbourhood) }
    let(:site) { create(:site, neighbourhoods: [neighbourhood]) }
    let(:address) { create(:address, neighbourhood: neighbourhood) }
    let(:partner) { create(:partner, address: address) }

    it "counts events in the current week" do
      create(:event, organiser: partner, dtstart: Time.zone.now)
      create(:event, organiser: partner, dtstart: 2.days.from_now)
      # Event outside the week
      create(:event, organiser: partner, dtstart: 2.weeks.from_now)

      expect(site.events_this_week).to eq(2)
    end

    it "returns 0 when no events exist" do
      expect(site.events_this_week).to eq(0)
    end
  end

  describe "#refresh_partners_count!" do
    let(:neighbourhood) { create(:neighbourhood) }
    let(:site) { create(:site, neighbourhoods: [neighbourhood]) }
    let(:address) { create(:address, neighbourhood: neighbourhood) }

    it "updates the cached partners_count" do
      create(:partner, address: address)
      create(:partner, address: address)

      site.refresh_partners_count!
      expect(site.reload.partners_count).to eq(2)
    end
  end

  describe "#refresh_events_count!" do
    let(:neighbourhood) { create(:neighbourhood) }
    let(:site) { create(:site, neighbourhoods: [neighbourhood]) }
    let(:address) { create(:address, neighbourhood: neighbourhood) }
    let(:partner) { create(:partner, address: address) }

    it "updates the cached events_count" do
      create(:event, organiser: partner, dtstart: Time.zone.now)
      create(:event, organiser: partner, dtstart: 1.day.from_now)

      site.refresh_events_count!
      expect(site.reload.events_count).to eq(2)
    end
  end

  describe ".sites_that_contain_partner" do
    let(:neighbourhood) { create(:neighbourhood) }
    let(:address) { create(:address, neighbourhood: neighbourhood) }
    let(:partner) { create(:partner, address: address) }

    it "returns published sites that contain the partner" do
      site = create(:site, is_published: true, neighbourhoods: [neighbourhood])

      expect(described_class.sites_that_contain_partner(partner)).to include(site)
    end

    it "excludes unpublished sites that contain the partner" do
      create(:site, is_published: false, neighbourhoods: [neighbourhood])

      expect(described_class.sites_that_contain_partner(partner)).to be_empty
    end

    it "returns only the published sites when both exist" do
      published = create(:site, is_published: true, neighbourhoods: [neighbourhood])
      create(:site, is_published: false, neighbourhoods: [neighbourhood])

      expect(described_class.sites_that_contain_partner(partner)).to contain_exactly(published)
    end
  end

  describe "scopes" do
    describe "default ordering" do
      let!(:site_a) { create(:site, name: "Alpha Site") }
      let!(:site_z) { create(:site, name: "Zeta Site") }

      it "can be ordered by name" do
        result = described_class.order(:name)
        expect(result.first).to eq(site_a)
        expect(result.last).to eq(site_z)
      end
    end
  end

  # Derived nav asks for this on every request of every site (#3368 D6).
  describe "#news_article_count" do
    let(:site) { create(:site) }
    let(:cache_key) { ["site", site.id, "news_article_count"] }

    around do |example|
      original = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = original
    end

    it "stores the computed count" do
      expect(site.news_article_count).to eq(0)
      expect(Rails.cache.read(cache_key)).to eq(0)
    end

    it "serves a later instance from the cache instead of counting again" do
      Rails.cache.write(cache_key, 7)

      expect(described_class.find(site.id).news_article_count).to eq(7)
    end

    it "caches for ten minutes rather than forever" do
      allow(Rails.cache).to receive(:fetch).and_call_original

      site.news_article_count

      expect(Rails.cache).to have_received(:fetch).with(cache_key, expires_in: 10.minutes)
    end

    it "keys the cache per site" do
      other = create(:site)
      Rails.cache.write(cache_key, 7)

      expect(other.news_article_count).to eq(0)
    end
  end
end
