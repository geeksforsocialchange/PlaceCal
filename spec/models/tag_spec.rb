# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:partner_tags).dependent(:destroy) }
    it { is_expected.to have_many(:partners).through(:partner_tags) }
    it { is_expected.to have_many(:tags_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:tags_users) }
    it { is_expected.to have_many(:sites_tag).dependent(:destroy) }
    it { is_expected.to have_many(:sites).through(:sites_tag) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
  end

  describe "STI types" do
    describe Category do
      it "is a subclass of Tag" do
        expect(described_class.superclass).to eq(Tag)
      end

      it "can be created" do
        category = create(:category_tag)
        expect(category).to be_a(described_class)
        expect(category.type).to eq("Category")
      end
    end

    describe Facility do
      it "is a subclass of Tag" do
        expect(described_class.superclass).to eq(Tag)
      end

      it "can be created" do
        facility = create(:facility_tag)
        expect(facility).to be_a(described_class)
        expect(facility.type).to eq("Facility")
      end
    end

    describe Partnership do
      it "is a subclass of Tag" do
        expect(described_class.superclass).to eq(Tag)
      end

      it "can be created" do
        partnership = create(:partnership_tag)
        expect(partnership).to be_a(described_class)
        expect(partnership.type).to eq("Partnership")
      end
    end
  end

  describe "factories" do
    it "creates a valid tag" do
      tag = build(:tag)
      expect(tag).to be_valid
    end

    it "creates Normal Island category tags" do
      tag = create(:community_services_tag)
      expect(tag).to be_a(Category)
      expect(tag.name).to eq("Community Services")
    end

    it "creates Normal Island facility tags" do
      tag = create(:wheelchair_accessible_tag)
      expect(tag).to be_a(Facility)
      expect(tag.name).to eq("Wheelchair Accessible")
    end

    it "creates Normal Island partnership tags" do
      tag = create(:millbrook_partnership_tag)
      expect(tag).to be_a(Partnership)
      expect(tag.name).to eq("Millbrook Together")
    end
  end

  describe "FriendlyId" do
    it "uses slug for URL" do
      tag = create(:tag, name: "Test Tag", slug: "test-tag")
      expect(tag.to_param).to eq("test-tag")
    end

    it "generates slug from name" do
      tag = create(:tag, name: "New Tag Name")
      expect(tag.slug).to eq("new-tag-name")
    end
  end

  describe "scopes" do
    before do
      create(:category_tag, name: "Category 1")
      create(:facility_tag, name: "Facility 1")
      create(:partnership_tag, name: "Partnership 1")
    end

    it "can filter by type" do
      expect(Category.count).to eq(1)
      expect(Facility.count).to eq(1)
      expect(Partnership.count).to eq(1)
    end
  end

  describe "partner associations" do
    let(:partner) { create(:partner) }
    let(:category) { create(:category_tag) }
    let(:facility) { create(:facility_tag) }
    let(:partnership) { create(:partnership_tag) }

    it "can associate with partners via partner_tags" do
      partner.tags << category
      partner.tags << facility
      partner.tags << partnership

      expect(partner.categories).to include(category)
      expect(partner.facilities).to include(facility)
      expect(partner.partnerships).to include(partnership)
    end
  end

  describe "user associations (Partnership only)" do
    let(:user) { create(:user) }
    let(:partnership) { create(:partnership_tag) }
    let(:category) { create(:category_tag) }

    it "allows Partnership tags to be assigned to users" do
      user.tags << partnership
      expect(user).to be_valid
      expect(user.tags).to include(partnership)
    end

    it "does not allow Category tags on users" do
      user.tags << category
      expect(user).not_to be_valid
    end
  end
end
