# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Partner, 'address or service area presence validation' do
  let(:user) do
    u = create(:neighbourhood_admin)
    u.neighbourhoods << neighbourhood
    u
  end
  let(:root_user) { create(:root) }
  let(:neighbourhood) { create(:riverside_ward) }
  let(:new_partner) do
    Partner.new(
      name: 'Alpha name',
      summary: 'Summary of alpha',
      accessed_by_user: user
    )
  end
  let(:new_partner_for_root) do
    Partner.new(
      name: 'Alpha name',
      summary: 'Summary of alpha',
      accessed_by_user: root_user
    )
  end

  describe 'with neighbourhood admin user' do
    it 'is invalid if both service area and address not present' do
      new_partner.validate

      expect(new_partner).not_to be_valid
      expect(new_partner.errors[:base].length).to be_positive
    end

    it 'is invalid if service area set outside neighbourhood and address not present' do
      new_partner.service_areas.build(neighbourhood: create(:neighbourhood))
      new_partner.validate

      expect(new_partner).not_to be_valid
      expect(new_partner.errors[:base].length).to be_positive
    end

    it 'is invalid if address set outside neighbourhood and service area not present' do
      build(:address, neighbourhood: create(:neighbourhood))
      new_partner.validate

      expect(new_partner).not_to be_valid
      expect(new_partner.errors[:base].length).to be_positive
    end

    it 'is valid with owned service_area set' do
      new_partner.service_areas.build(neighbourhood: neighbourhood)
      new_partner.validate

      expect(new_partner).to be_valid
    end

    it 'is valid with owned address set' do
      address = build(:address, neighbourhood: neighbourhood)

      new_partner.address = address
      new_partner.save!

      expect(new_partner).to be_valid
    end
  end

  describe 'with root user' do
    it 'is invalid if both service area and address not present' do
      new_partner_for_root.validate

      expect(new_partner_for_root).not_to be_valid
      expect(new_partner_for_root.errors[:base].length).to be_positive
    end

    it 'is valid with service_area set' do
      new_partner_for_root.service_areas.build(neighbourhood: create(:neighbourhood))
      new_partner_for_root.validate

      expect(new_partner_for_root).to be_valid
    end

    it 'is valid with address set' do
      address = build(:address, neighbourhood: create(:neighbourhood))

      new_partner_for_root.address = address
      new_partner_for_root.save!

      expect(new_partner_for_root).to be_valid
    end

    it 'is valid with both service_area and address set' do
      address = build(:address)

      new_partner_for_root.address = address
      new_partner_for_root.service_areas.build(neighbourhood: create(:neighbourhood))
      new_partner_for_root.validate

      expect(new_partner_for_root).to be_valid
    end
  end
end
