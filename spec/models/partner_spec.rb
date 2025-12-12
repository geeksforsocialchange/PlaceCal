# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Partner, type: :model do
  describe 'associations' do
    it { is_expected.to have_and_belong_to_many(:users) }
    it { is_expected.to have_many(:calendars).dependent(:destroy) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to have_many(:partner_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:partner_tags) }
    it { is_expected.to have_many(:categories).through(:partner_tags) }
    it { is_expected.to have_many(:facilities).through(:partner_tags) }
    it { is_expected.to have_many(:partnerships).through(:partner_tags) }
    it { is_expected.to have_many(:service_areas).dependent(:destroy) }
    it { is_expected.to have_many(:article_partners).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_partners) }
  end

  describe 'validations' do
    describe 'name' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

      it 'requires minimum length of 5 characters' do
        partner = build(:partner, name: '1234')
        expect(partner).not_to be_valid
        expect(partner.errors[:name]).to include('must be at least 5 characters long')
      end
    end

    describe 'summary and description' do
      let(:partner) { build(:partner) }

      it 'allows no summary or description' do
        partner.summary = ''
        partner.description = ''
        expect(partner).to be_valid
      end

      it 'allows summary without description' do
        partner.summary = 'This is a test summary'
        partner.description = ''
        expect(partner).to be_valid
      end

      it 'does not allow description without summary' do
        partner.summary = ''
        partner.description = 'This is a description'
        expect(partner).not_to be_valid
        expect(partner.errors[:summary]).to include('cannot have a description without a summary')
      end

      it 'allows both summary and description' do
        partner.summary = 'This is a test summary'
        partner.description = 'This is a description'
        expect(partner).to be_valid
      end

      it 'limits summary to 200 characters' do
        partner.summary = 'a' * 201
        expect(partner).not_to be_valid
        expect(partner.errors[:summary]).to be_present
      end
    end

    describe 'url' do
      let(:partner) { build(:partner) }

      it 'accepts valid URLs' do
        partner.url = 'https://good-domain.com'
        partner.valid?
        expect(partner.errors[:url]).to be_empty
      end

      it 'rejects invalid URLs' do
        partner.url = 'htp://bad-domain.co'
        expect(partner).not_to be_valid
        expect(partner.errors[:url]).to include('is invalid')
      end

      it 'allows blank URL' do
        partner.url = ''
        partner.valid?
        expect(partner.errors[:url]).to be_empty
      end
    end

    describe 'twitter_handle' do
      let(:partner) { build(:partner) }

      it 'accepts valid handle with @' do
        partner.twitter_handle = '@asdf'
        partner.valid?
        expect(partner.errors[:twitter_handle]).to be_empty
      end

      it 'accepts valid handle without @' do
        partner.twitter_handle = 'asdf'
        partner.valid?
        expect(partner.errors[:twitter_handle]).to be_empty
      end

      it 'rejects full URL' do
        partner.twitter_handle = 'https://twitter.com/asdf'
        expect(partner).not_to be_valid
        expect(partner.errors[:twitter_handle]).to be_present
      end

      it 'rejects invalid characters' do
        partner.twitter_handle = 'asd£$%dsa'
        expect(partner).not_to be_valid
        expect(partner.errors[:twitter_handle]).to be_present
      end
    end

    describe 'facebook_link' do
      let(:partner) { build(:partner) }

      it 'accepts valid page name' do
        partner.facebook_link = 'GroupName'
        partner.valid?
        expect(partner.errors[:facebook_link]).to be_empty
      end

      it 'rejects full URL' do
        partner.facebook_link = 'https://facebook.com/group-name'
        expect(partner).not_to be_valid
        expect(partner.errors[:facebook_link]).to be_present
      end

      it 'rejects hyphenated names' do
        partner.facebook_link = 'Group-Name'
        expect(partner).not_to be_valid
        expect(partner.errors[:facebook_link]).to be_present
      end
    end

    describe 'address or service area requirement' do
      let(:partner) { create(:partner) }

      it 'requires at least address or service area' do
        partner.service_areas.destroy_all
        partner.address = nil
        expect(partner).not_to be_valid
        expect(partner.errors[:base]).to include('Partners must have at least one of service area or address')
      end
    end
  end

  describe 'factories' do
    it 'creates a valid partner' do
      partner = build(:partner)
      expect(partner).to be_valid
    end

    it 'creates a riverside partner' do
      partner = create(:riverside_partner)
      expect(partner.name).to eq('Riverside Community Hub')
      expect(partner.address).to be_present
    end

    it 'creates a mobile partner with service areas' do
      ward = create(:riverside_ward)
      partner = create(:mobile_partner, service_area_wards: [ward])
      expect(partner.service_areas.count).to eq(1)
    end
  end

  describe 'tag associations' do
    let(:partner) { create(:partner) }

    it 'can have Category tags' do
      category = create(:category_tag)
      partner.tags << category
      partner.save
      expect(partner.categories.count).to eq(1)
    end

    it 'can have Facility tags' do
      facility = create(:facility_tag)
      partner.tags << facility
      partner.save
      expect(partner.facilities.count).to eq(1)
    end

    it 'can have Partnership tags' do
      partnership = create(:partnership_tag)
      partner.tags << partnership
      partner.save
      expect(partner.partnerships.count).to eq(1)
    end

    it 'limits Category tags to 3' do
      4.times { |n| partner.categories << create(:category_tag, name: "Category #{n}") }
      partner.save
      expect(partner.errors[:categories]).to include('Partners can have a maximum of 3 Category tags')
    end

    it 'allows up to 3 Category tags' do
      3.times { |n| partner.categories << create(:category_tag, name: "Category #{n}") }
      partner.save
      expect(partner).to be_valid
    end
  end

  describe 'hiding partners' do
    let(:partner) { build(:partner) }

    it 'cannot be hidden without a reason' do
      partner.hidden = true
      partner.hidden_blame_id = 1
      expect(partner).not_to be_valid
    end

    it 'cannot be hidden without recording who hid it' do
      partner.hidden = true
      partner.hidden_reason = 'Something wrong'
      expect(partner).not_to be_valid
    end

    it 'can be hidden with reason and blame_id' do
      partner.hidden = true
      partner.hidden_reason = 'Something wrong'
      partner.hidden_blame_id = 1
      expect(partner).to be_valid
    end
  end

  describe 'user role management' do
    let(:user) { create(:user) }
    let(:partner) { create(:partner, accessed_by_user: user) }

    it 'makes user a partner_admin when assigned' do
      user.partners << partner
      user.save
      expect(user).to be_partner_admin
    end
  end

  describe 'address changes' do
    let(:user) { create(:root_user) }
    let(:partner) { create(:partner, accessed_by_user: user) }

    it 'can update postcode' do
      new_postcode = 'NOAD 1HC' # Hillcrest
      partner.update!(
        address_attributes: {
          id: partner.address.id,
          street_address: partner.address.street_address,
          postcode: new_postcode
        }
      )
      partner.reload
      expect(partner.address.postcode).to eq(new_postcode)
    end
  end

  describe 'opening times' do
    it 'handles badly formatted opening times' do
      partner = build(:partner)
      partner.opening_times = '{{ $data.openingHoursSpecifications }}'
      expect(partner.human_readable_opening_times).to be_empty
    end

    it 'defaults to empty array' do
      partner = described_class.new
      expect(partner.opening_times_data).to eq('[]')
    end

    it 'accepts valid JSON' do
      opening_times = [
        { opens: '09:00', closes: '17:00' },
        { opens: '09:00', closes: '17:00' }
      ].to_json

      partner = described_class.new(opening_times: opening_times)
      found = JSON.parse(partner.opening_times_data)
      expect(found.length).to eq(2)
    end
  end

  describe 'scopes' do
    describe '.visible' do
      it 'excludes hidden partners' do
        visible = create(:partner)
        hidden = create(:partner, hidden: true, hidden_reason: 'Test', hidden_blame_id: 1)

        expect(described_class.visible).to include(visible)
        expect(described_class.visible).not_to include(hidden)
      end
    end

    describe '.from_neighbourhoods_and_service_areas' do
      let(:ward) { create(:riverside_ward) }
      let(:partner_with_address) do
        address = create(:riverside_address)
        create(:partner, address: address)
      end
      let(:partner_with_service_area) do
        partner = create(:mobile_partner, service_area_wards: [ward])
        partner
      end

      it 'finds partners by address neighbourhood' do
        partner_with_address
        result = described_class.from_neighbourhoods_and_service_areas([partner_with_address.address.neighbourhood_id])
        expect(result).to include(partner_with_address)
      end

      it 'finds partners by service area neighbourhood' do
        partner_with_service_area
        result = described_class.from_neighbourhoods_and_service_areas([ward.id])
        expect(result).to include(partner_with_service_area)
      end
    end
  end

  describe '#can_clear_address?' do
    let(:ward) { create(:riverside_ward) }

    it 'returns false when partner has no address' do
      partner = build(:partner, address: nil)
      partner.service_areas.build(neighbourhood: ward)
      expect(partner.can_clear_address?).to be false
    end

    it 'returns false when partner has no service areas' do
      partner = build(:partner)
      expect(partner.can_clear_address?).to be false
    end

    it 'returns true for root user with address and service areas' do
      root = create(:root_user)
      partner = build(:partner)
      partner.service_areas.build(neighbourhood: ward)
      expect(partner.can_clear_address?(root)).to be true
    end

    it 'returns true for partner admin' do
      citizen = create(:user)
      partner = create(:partner)
      partner.service_areas.create(neighbourhood: ward)
      citizen.partners << partner
      expect(partner.can_clear_address?(citizen)).to be true
    end
  end

  describe '#neighbourhood_name_for_site' do
    let(:partner) { create(:riverside_partner) }

    it 'returns ward name at ward level' do
      expect(partner.neighbourhood_name_for_site('ward')).to eq('Riverside')
    end
  end
end
