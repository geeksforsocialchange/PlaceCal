# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerLocationsQuery do
  describe "#call" do
    # The service-area centroid fallback (for address-less partners) is exercised
    # end-to-end by the directory home request spec, which renders this query.
    it "includes visible partners with geocoded addresses" do
      partner = create(:partner)

      entry = described_class.new.call.find { |l| l[:slug] == partner.slug }

      expect(entry).to include(
        name: partner.name,
        lat: partner.address.latitude,
        lon: partner.address.longitude
      )
    end

    it "excludes hidden partners" do
      partner = create(:partner, hidden: true, hidden_reason: "Test", hidden_blame_id: 1)

      slugs = described_class.new.call.map { |l| l[:slug] }
      expect(slugs).not_to include(partner.slug)
    end

    it "excludes partners whose address has no coordinates" do
      partner = create(:partner)
      partner.address.update!(latitude: nil, longitude: nil)

      slugs = described_class.new.call.map { |l| l[:slug] }
      expect(slugs).not_to include(partner.slug)
    end
  end
end
