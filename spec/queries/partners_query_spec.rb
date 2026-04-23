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

  describe "#call with pagination" do
    let!(:partners) do
      ("A".."E").map do |letter|
        address = create(:address, neighbourhood: neighbourhood)
        create(:partner, name: "#{letter} Partner", address: address)
      end
    end

    it "returns only the requested page of results" do
      results = described_class.new(site: site).call(page: 1, per_page: 2)
      expect(results.map(&:name)).to eq(["A Partner", "B Partner"])
    end

    it "returns the second page" do
      results = described_class.new(site: site).call(page: 2, per_page: 2)
      expect(results.map(&:name)).to eq(["C Partner", "D Partner"])
    end

    it "returns the last page with remaining items" do
      results = described_class.new(site: site).call(page: 3, per_page: 2)
      expect(results.map(&:name)).to eq(["E Partner"])
    end

    it "sets total_pages" do
      query = described_class.new(site: site)
      query.call(page: 1, per_page: 2)
      expect(query.total_pages).to eq(3)
    end

    it "sets total_count" do
      query = described_class.new(site: site)
      query.call(page: 1, per_page: 2)
      expect(query.total_count).to eq(5)
    end

    it "clamps page to valid range" do
      results = described_class.new(site: site).call(page: 999, per_page: 2)
      # Should clamp to last page
      expect(results.map(&:name)).to eq(["E Partner"])
    end

    it "returns all results when page is nil" do
      results = described_class.new(site: site).call
      expect(results.count).to eq(5)
    end
  end

  describe "#page_letter_ranges" do
    let!(:partners) do
      %w[Alpha Bravo Charlie Delta Epsilon].each do |name|
        address = create(:address, neighbourhood: neighbourhood)
        create(:partner, name: name, address: address)
      end
    end

    it "returns letter ranges for each page" do
      query = described_class.new(site: site)
      query.call(page: 1, per_page: 2)
      ranges = query.page_letter_ranges(per_page: 2)

      expect(ranges.length).to eq(3)
      expect(ranges[0][:page]).to eq(1)
      expect(ranges[0][:first_label]).to eq("A")
    end

    it "uses two-char prefix when letter spans boundary" do
      # With per_page: 3, page 1 = Alpha, Bravo, Charlie; page 2 = Delta, Epsilon
      query = described_class.new(site: site)
      query.call(page: 1, per_page: 3)
      ranges = query.page_letter_ranges(per_page: 3)

      expect(ranges.length).to eq(2)
      expect(ranges[0][:last_label]).to eq("C")
      expect(ranges[1][:first_label]).to eq("D")
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
