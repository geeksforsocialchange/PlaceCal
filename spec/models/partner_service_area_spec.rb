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
      partner.address = create(:address, neighbourhood:)
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
      partner.address = create(:address, neighbourhood:)
      partner.save!

      expect do
        partner.service_areas.create!(neighbourhood:)
        partner.service_areas.create!(neighbourhood:)
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
      partner.address = create(:address, neighbourhood:)
      partner.save!

      other_neighbourhood = create(:ashton_neighbourhood)
      partner.service_areas.create!(neighbourhood:)
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

  describe "removing service areas" do
    let(:ward) { create(:riverside_ward) }
    let(:other_ward) { create(:oldtown_ward) }
    let(:outside_ward) { create(:hillcrest_ward) }
    let(:message) { "Partners must have an address or a service area inside your neighbourhood" }
    let(:admin) { create(:neighbourhood_admin, neighbourhood: ward) }

    def create_partner(*neighbourhoods, address: nil)
      partner = build(:partner, address:)
      neighbourhoods.each { |n| partner.service_areas.build(neighbourhood: n) }
      partner.save!
      partner
    end

    def remove_area(partner, user, neighbourhood)
      partner.accessed_by_user = user
      partner.service_areas.destroy(partner.service_areas.find_by(neighbourhood:))
    end

    def remaining_ids(partner)
      partner.service_areas.reload.map(&:neighbourhood_id)
    end

    it "lets a neighbourhood admin remove an area when the remaining areas are inside their neighbourhoods" do
      admin.neighbourhoods << other_ward
      partner = create_partner(ward, other_ward)

      remove_area(partner, admin, ward)

      expect(remaining_ids(partner)).to eq([other_ward.id])
      expect(partner.errors[:service_areas]).to be_empty
    end

    it "stops a neighbourhood admin removing an area when a remaining area is outside their neighbourhoods" do
      partner = create_partner(ward, outside_ward)

      remove_area(partner, admin, ward)

      expect(remaining_ids(partner)).to contain_exactly(ward.id, outside_ward.id)
      expect(partner.errors[:service_areas]).to include(message)
    end

    it "stops a neighbourhood admin removing the last area when the partner has no address" do
      partner = create_partner(ward)

      remove_area(partner, admin, ward)

      expect(remaining_ids(partner)).to eq([ward.id])
      expect(partner.errors[:service_areas]).to include(message)
    end

    it "lets a neighbourhood admin remove an area when the partner's address is in their neighbourhood" do
      partner = create_partner(ward, outside_ward, address: create(:address, neighbourhood: ward))

      remove_area(partner, admin, ward)

      expect(remaining_ids(partner)).to eq([outside_ward.id])
      expect(partner.errors[:service_areas]).to be_empty
    end

    it "lets a root user remove an area outside their neighbourhoods" do
      partner = create_partner(ward, outside_ward)

      remove_area(partner, create(:root), ward)

      expect(remaining_ids(partner)).to eq([outside_ward.id])
    end

    it "lets a partner admin remove an area outside their neighbourhoods" do
      partner = create_partner(ward, outside_ward)

      remove_area(partner, create(:partner_admin, partner:), ward)

      expect(remaining_ids(partner)).to eq([outside_ward.id])
    end
  end
end
