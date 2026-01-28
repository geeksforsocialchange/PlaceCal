# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnersQuery do
  let(:site) { create(:site) }
  let(:neighbourhood) { create(:neighbourhood) }
  let(:other_neighbourhood) { create(:neighbourhood) }

  before do
    site.neighbourhoods << neighbourhood
    site.neighbourhoods << other_neighbourhood
  end

  describe "#call" do
    context "with partners in site neighbourhoods" do
      let!(:partner_with_address) do
        address = create(:address, neighbourhood: neighbourhood)
        create(:partner, address: address)
      end

      let!(:partner_with_service_area) do
        partner = build(:partner, address: nil)
        partner.service_area_neighbourhoods << neighbourhood
        partner.save!
        partner
      end

      let!(:partner_outside_site) do
        outside_neighbourhood = create(:neighbourhood)
        address = create(:address, neighbourhood: outside_neighbourhood)
        create(:partner, address: address)
      end

      it "returns partners with addresses in site neighbourhoods" do
        results = described_class.new(site: site).call

        expect(results).to include(partner_with_address)
      end

      it "returns partners with service areas in site neighbourhoods" do
        results = described_class.new(site: site).call

        expect(results).to include(partner_with_service_area)
      end

      it "excludes partners outside site neighbourhoods" do
        results = described_class.new(site: site).call

        expect(results).not_to include(partner_outside_site)
      end

      it "returns partners ordered by name" do
        results = described_class.new(site: site).call

        expect(results).to eq(results.sort_by(&:name))
      end
    end

    context "with neighbourhood filter" do
      let!(:partner_in_neighbourhood) do
        address = create(:address, neighbourhood: neighbourhood)
        create(:partner, address: address)
      end

      let!(:partner_in_other_neighbourhood) do
        address = create(:address, neighbourhood: other_neighbourhood)
        create(:partner, address: address)
      end

      it "filters partners by neighbourhood" do
        results = described_class.new(site: site).call(neighbourhood_id: neighbourhood.id)

        expect(results).to include(partner_in_neighbourhood)
        expect(results).not_to include(partner_in_other_neighbourhood)
      end
    end

    context "with tag filter" do
      let!(:category) { create(:category) }
      let!(:partner_with_tag) do
        address = create(:address, neighbourhood: neighbourhood)
        partner = create(:partner, address: address)
        partner.tags << category
        partner
      end

      let!(:partner_without_tag) do
        address = create(:address, neighbourhood: neighbourhood)
        create(:partner, address: address)
      end

      it "filters partners by tag" do
        results = described_class.new(site: site).call(tag_id: category.id)

        expect(results).to include(partner_with_tag)
        expect(results).not_to include(partner_without_tag)
      end
    end

    context "with empty site" do
      let(:empty_site) { create(:site) }

      it "returns empty relation" do
        results = described_class.new(site: empty_site).call

        expect(results).to be_empty
      end
    end
  end

  describe "#neighbourhoods_with_counts" do
    let!(:partner1) do
      address = create(:address, neighbourhood: neighbourhood)
      create(:partner, address: address)
    end

    let!(:partner2) do
      address = create(:address, neighbourhood: neighbourhood)
      create(:partner, address: address)
    end

    let!(:partner_other) do
      address = create(:address, neighbourhood: other_neighbourhood)
      create(:partner, address: address)
    end

    it "returns neighbourhoods with partner counts" do
      results = described_class.new(site: site).neighbourhoods_with_counts

      neighbourhood_result = results.find { |r| r[:neighbourhood].id == neighbourhood.id }
      expect(neighbourhood_result[:count]).to eq(2)
    end

    it "orders neighbourhoods by name" do
      results = described_class.new(site: site).neighbourhoods_with_counts

      names = results.map { |r| r[:neighbourhood].name }
      expect(names).to eq(names.sort)
    end
  end

  describe "#categories_with_counts" do
    let!(:category1) { create(:category, name: "Arts") }
    let!(:category2) { create(:category, name: "Sports") }

    let!(:partner1) do
      address = create(:address, neighbourhood: neighbourhood)
      partner = create(:partner, address: address)
      partner.tags << category1
      partner
    end

    let!(:partner2) do
      address = create(:address, neighbourhood: neighbourhood)
      partner = create(:partner, address: address)
      partner.tags << category1
      partner
    end

    let!(:partner3) do
      address = create(:address, neighbourhood: neighbourhood)
      partner = create(:partner, address: address)
      partner.tags << category2
      partner
    end

    it "returns categories with partner counts" do
      results = described_class.new(site: site).categories_with_counts

      category1_result = results.find { |r| r[:category].id == category1.id }
      expect(category1_result[:count]).to eq(2)

      category2_result = results.find { |r| r[:category].id == category2.id }
      expect(category2_result[:count]).to eq(1)
    end

    it "orders categories by name" do
      results = described_class.new(site: site).categories_with_counts

      names = results.map { |r| r[:category].name }
      expect(names).to eq(names.sort)
    end
  end
end
