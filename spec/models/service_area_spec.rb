# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceArea do
  let(:partner) { create(:partner) }
  let(:neighbourhood) { create(:riverside_ward) }

  describe "validations" do
    it "is valid with a partner and neighbourhood" do
      service_area = build(:service_area, partner: partner, neighbourhood: neighbourhood)

      expect(service_area).to be_valid
    end

    it "is invalid when the same neighbourhood is added twice for the same partner" do
      create(:service_area, partner: partner, neighbourhood: neighbourhood)
      duplicate = build(:service_area, partner: partner, neighbourhood: neighbourhood)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:neighbourhood_id])
        .to include("cannot be added more than once as a service area")
    end

    it "is valid when a partner has two different neighbourhoods" do
      other_neighbourhood = create(:oldtown_ward)
      create(:service_area, partner: partner, neighbourhood: neighbourhood)
      second = build(:service_area, partner: partner, neighbourhood: other_neighbourhood)

      expect(second).to be_valid
    end

    it "allows the same neighbourhood for two different partners" do
      other_partner = create(:partner)
      create(:service_area, partner: partner, neighbourhood: neighbourhood)
      other = build(:service_area, partner: other_partner, neighbourhood: neighbourhood)

      expect(other).to be_valid
    end
  end
end
