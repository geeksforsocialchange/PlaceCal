# frozen_string_literal: true

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
    it { is_expected.to validate_presence_of(:slug) }

    # NOTE: FriendlyId handles slug uniqueness at the database level
    # No explicit validates_uniqueness_of on slug in the model
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
      create(:event, partner: partner, dtstart: Time.zone.now)
      create(:event, partner: partner, dtstart: 2.days.from_now)
      # Event outside the week
      create(:event, partner: partner, dtstart: 2.weeks.from_now)

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
      create(:event, partner: partner, dtstart: Time.zone.now)
      create(:event, partner: partner, dtstart: 1.day.from_now)

      site.refresh_events_count!
      expect(site.reload.events_count).to eq(2)
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
end
