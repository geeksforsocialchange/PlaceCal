# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Neighbourhood, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:sites_neighbourhoods).dependent(:destroy) }
    it { is_expected.to have_many(:sites).through(:sites_neighbourhoods) }
    it { is_expected.to have_many(:neighbourhoods_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:neighbourhoods_users) }
    it { is_expected.to have_many(:service_areas).dependent(:destroy) }
    it { is_expected.to have_many(:addresses).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to allow_value('NO4000001').for(:unit_code_value) }
    it { is_expected.to allow_value('').for(:unit_code_value) }
    # unit_code_value must be exactly 9 characters or blank
    it { is_expected.not_to allow_value('TOOLONG123').for(:unit_code_value) }
    it { is_expected.not_to allow_value('SHORT').for(:unit_code_value) }
  end

  describe 'ancestry navigation' do
    let(:ward) { create(:riverside_ward) }

    it 'can access district through ancestors' do
      expect(ward.district).to be_present
      expect(ward.district.name).to eq('Millbrook')
      expect(ward.district.unit).to eq('district')
    end

    it 'can access county through ancestors' do
      expect(ward.county).to be_present
      expect(ward.county.name).to eq('Greater Millbrook')
      expect(ward.county.unit).to eq('county')
    end

    it 'can access region through ancestors' do
      expect(ward.region).to be_present
      expect(ward.region.name).to eq('Northvale')
      expect(ward.region.unit).to eq('region')
    end

    it 'can access country through ancestors' do
      expect(ward.country).to be_present
      expect(ward.country.name).to eq('Normal Island')
      expect(ward.country.unit).to eq('country')
    end
  end

  describe '#abbreviated_name' do
    it 'returns name_abbr when present' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: 'Abbr')
      expect(neighbourhood.abbreviated_name).to eq('Abbr')
    end

    it 'returns name when name_abbr is missing' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: nil)
      expect(neighbourhood.abbreviated_name).to eq('Full Name')
    end

    it 'returns name when name_abbr is empty string' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: '')
      expect(neighbourhood.abbreviated_name).to eq('Full Name')
    end

    it 'returns name when name_abbr is blank string' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: '   ')
      expect(neighbourhood.abbreviated_name).to eq('Full Name')
    end
  end

  describe '#shortname' do
    it 'returns name_abbr when present' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: 'Short')
      expect(neighbourhood.shortname).to eq('Short')
    end

    it 'returns name when name_abbr is missing' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: nil)
      expect(neighbourhood.shortname).to eq('Full Name')
    end

    it 'returns placeholder when both are missing' do
      neighbourhood = build(:neighbourhood, name: nil, name_abbr: nil)
      expect(neighbourhood.shortname).to eq('[not set]')
    end
  end

  describe '#fullname' do
    it 'returns name when present' do
      neighbourhood = build(:neighbourhood, name: 'Full Name', name_abbr: 'Short')
      expect(neighbourhood.fullname).to eq('Full Name')
    end

    it 'returns name_abbr when name is missing' do
      neighbourhood = build(:neighbourhood, name: nil, name_abbr: 'Short')
      expect(neighbourhood.fullname).to eq('Short')
    end

    it 'returns placeholder when both are missing' do
      neighbourhood = build(:neighbourhood, name: nil, name_abbr: nil)
      expect(neighbourhood.fullname).to eq('[not set]')
    end
  end

  describe '#contextual_name' do
    let(:ward) { create(:riverside_ward) }

    it 'includes parent name and unit type' do
      # NOTE: parent_name is set on update via callback
      ward.update!(parent_name: ward.parent.name)
      expect(ward.contextual_name).to include('Riverside')
      expect(ward.contextual_name).to include('Ward')
    end
  end

  describe '#legacy_neighbourhood?' do
    it 'returns true for neighbourhoods with old release dates' do
      neighbourhood = build(:neighbourhood, release_date: DateTime.new(2020, 1))
      expect(neighbourhood.legacy_neighbourhood?).to be true
    end

    it 'returns false for neighbourhoods with current release dates' do
      neighbourhood = build(:neighbourhood, release_date: Neighbourhood::LATEST_RELEASE_DATE)
      expect(neighbourhood.legacy_neighbourhood?).to be false
    end
  end

  describe '.latest_release scope' do
    before do
      create(:neighbourhood, name: 'Current 1', release_date: Neighbourhood::LATEST_RELEASE_DATE)
      create(:neighbourhood, name: 'Current 2', release_date: Neighbourhood::LATEST_RELEASE_DATE)
      create(:neighbourhood, name: 'Old', release_date: DateTime.new(1990, 1))
    end

    it 'returns only neighbourhoods with the latest release date' do
      result = described_class.latest_release
      expect(result.count).to eq(2)
      expect(result.pluck(:name)).to contain_exactly('Current 1', 'Current 2')
    end
  end

  describe '.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods' do
    let!(:latest) do
      Array.new(3) { |n| create(:neighbourhood, name: "Latest #{n}", release_date: Neighbourhood::LATEST_RELEASE_DATE) }
    end

    let!(:obsolete) do
      Array.new(5) { |n| create(:neighbourhood, name: "Obsolete #{n}", release_date: DateTime.new(1990, 1)) }
    end

    it 'finds only latest neighbourhoods when no legacy provided' do
      result = described_class.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(described_class, [])
      expect(result.count).to eq(3)
    end

    it 'includes specified legacy neighbourhoods' do
      legacy = [obsolete[0], obsolete[2]]
      result = described_class.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(described_class, legacy)
      expect(result.count).to eq(5) # 3 latest + 2 legacy
    end
  end

  describe '.find_from_postcodesio_response' do
    let!(:ward) { create(:riverside_ward) }

    it 'finds neighbourhood by ONS admin_ward code' do
      response = { 'codes' => { 'admin_ward' => ward.unit_code_value } }
      result = described_class.find_from_postcodesio_response(response)
      expect(result).to eq(ward)
    end

    it 'returns nil when no match found' do
      response = { 'codes' => { 'admin_ward' => 'NONEXIST1' } }
      result = described_class.find_from_postcodesio_response(response)
      expect(result).to be_nil
    end
  end
end
