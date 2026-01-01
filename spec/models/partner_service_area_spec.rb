# frozen_string_literal: true

require "rails_helper"

RSpec.describe Partner, "service_area" do
  let(:neighbourhood) { create(:riverside_ward) }
  let(:user) do
    u = create(:user)
    u.neighbourhoods << neighbourhood
    u
  end
  let(:partner) { build(:partner, address: nil, accessed_by_user: user) }

  describe "validations" do
    it "is valid when empty" do
      partner.address = create(:address, neighbourhood: neighbourhood)
      partner.save!

      expect(partner).to be_valid
    end

    it "is valid when set, can be accessed" do
      # Must use create() to trigger after(:create) callback that adds service_area
      model = create(:ashton_service_area_partner)
      expect(model).to be_valid

      service_areas = model.service_areas
      expect(service_areas.count).to eq(1)
    end

    it "can be assigned" do
      partner.accessed_by_user = user
      partner.service_area_neighbourhoods << neighbourhood
      partner.save!

      expect(partner).to be_valid

      neighbourhood_count = partner.service_area_neighbourhoods.count
      expect(neighbourhood_count).to eq(1)
    end

    it "must be unique" do
      partner.address = create(:address, neighbourhood: neighbourhood)
      partner.save!

      expect do
        partner.service_areas.create!(neighbourhood: neighbourhood)
        partner.service_areas.create!(neighbourhood: neighbourhood)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "must be within users neighbourhoods" do
      partner.service_areas.build(neighbourhood: create(:moss_side_neighbourhood))
      partner.validate

      expect(partner).not_to be_valid
    end
  end

  describe "reading service areas" do
    it "can be read when present" do
      partner.address = create(:address, neighbourhood: neighbourhood)
      partner.save!

      other_neighbourhood = create(:ashton_neighbourhood)
      partner.service_areas.create!(neighbourhood: neighbourhood)
      partner.service_areas.create!(neighbourhood: other_neighbourhood)

      neighbourhoods = partner.service_area_neighbourhoods.order("neighbourhoods.name").all
      expect(neighbourhoods.count).to eq(2)

      # Names are ordered alphabetically: 'Ashton' < 'Riverside'
      n1 = neighbourhoods[0]
      expect(n1.name).to eq("Ashton")

      n2 = neighbourhoods[1]
      expect(n2.name).to eq("Riverside")
    end
  end

  describe "root users" do
    it "can be set by root users" do
      root_user = create(:root)
      other_neighbourhood = create(:moss_side_neighbourhood)

      partner.accessed_by_user = root_user
      partner.service_area_neighbourhoods << other_neighbourhood
      partner.save!

      expect(partner).to be_valid

      neighbourhood_count = partner.service_area_neighbourhoods.count
      expect(neighbourhood_count).to eq(1)
    end
  end
end
