# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_and_belong_to_many(:partners) }
    it { is_expected.to have_many(:neighbourhoods_users).dependent(:destroy) }
    it { is_expected.to have_many(:neighbourhoods).through(:neighbourhoods_users) }
    it { is_expected.to have_many(:tags_users).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:tags_users) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:role) }
  end

  describe 'factories' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a root user' do
      user = create(:root_user)
      expect(user.role).to eq('root')
      expect(user).to be_root
    end

    it 'creates a citizen user' do
      user = create(:citizen_user)
      expect(user.role).to eq('citizen')
      expect(user).to be_citizen
    end

    it 'creates an editor user' do
      user = create(:editor_user)
      expect(user.role).to eq('editor')
      expect(user).to be_editor
    end

    it 'creates a neighbourhood admin' do
      user = create(:neighbourhood_admin)
      expect(user).to be_neighbourhood_admin
    end

    it 'creates a partner admin' do
      user = create(:partner_admin)
      expect(user).to be_partner_admin
    end

    it 'creates a partnership admin' do
      user = create(:partnership_admin)
      expect(user).to be_partnership_admin
    end
  end

  describe '#full_name' do
    let(:user) { build(:user) }

    it 'returns first and last name joined' do
      user.first_name = 'Joan'
      user.last_name = 'Jones'
      expect(user.full_name).to eq('Joan Jones')
    end

    it 'returns just first name when last is blank' do
      user.first_name = 'Joan'
      user.last_name = ''
      expect(user.full_name).to eq('Joan')
    end

    it 'returns just last name when first is blank' do
      user.first_name = ''
      user.last_name = 'Jones'
      expect(user.full_name).to eq('Jones')
    end

    it 'returns empty string when both are blank' do
      user.first_name = ''
      user.last_name = ''
      expect(user.full_name).to eq('')
    end
  end

  describe '#admin_name' do
    let(:user) { build(:user, email: 'test@example.com') }

    it 'formats with uppercase last name first' do
      user.first_name = 'Joan'
      user.last_name = 'Jones'
      expect(user.admin_name).to eq('JONES, Joan <test@example.com>')
    end

    it 'handles missing last name' do
      user.first_name = 'Joan'
      user.last_name = ''
      expect(user.admin_name).to eq('Joan <test@example.com>')
    end

    it 'handles missing first name' do
      user.first_name = ''
      user.last_name = 'Jones'
      expect(user.admin_name).to eq('JONES <test@example.com>')
    end
  end

  describe 'role predicates' do
    it '#root? returns true for root role' do
      user = build(:user, role: :root)
      expect(user).to be_root
    end

    it '#citizen? returns true for citizen role' do
      user = build(:user, role: :citizen)
      expect(user).to be_citizen
    end

    it '#editor? returns true for editor role' do
      user = build(:user, role: :editor)
      expect(user).to be_editor
    end
  end

  describe '#neighbourhood_admin?' do
    it 'returns true when user has neighbourhoods' do
      user = create(:neighbourhood_admin)
      expect(user).to be_neighbourhood_admin
    end

    it 'returns false when user has no neighbourhoods' do
      user = create(:user)
      expect(user).not_to be_neighbourhood_admin
    end
  end

  describe '#partner_admin?' do
    it 'returns true when user has partners' do
      user = create(:partner_admin)
      expect(user).to be_partner_admin
    end

    it 'returns false when user has no partners' do
      user = create(:user)
      expect(user).not_to be_partner_admin
    end
  end

  describe '#partnership_admin?' do
    it 'returns true when user has partnership tags' do
      user = create(:partnership_admin)
      expect(user).to be_partnership_admin
    end

    it 'returns false when user has no partnership tags' do
      user = create(:user)
      expect(user).not_to be_partnership_admin
    end
  end

  describe '#admin_for_partner?' do
    let(:user) { create(:user) }
    let(:partner) { create(:partner) }

    it 'returns true when user is assigned to partner' do
      user.partners << partner
      expect(user.admin_for_partner?(partner.id)).to be true
    end

    it 'returns false when user is not assigned to partner' do
      expect(user.admin_for_partner?(partner.id)).to be false
    end
  end

  describe '#owned_neighbourhoods' do
    # Create ward first - this builds the full hierarchy (ward -> district -> county -> region -> country)
    let!(:ward) { create(:riverside_ward) }
    let(:district) { ward.parent } # millbrook_district
    let(:user) { create(:neighbourhood_admin, neighbourhood: district) }

    it 'returns all descendant neighbourhoods' do
      owned = user.owned_neighbourhoods
      expect(owned).to include(district)
      # The subtree includes the district itself and its children (wards)
      expect(owned.count).to be > 1
      expect(owned).to include(ward)
    end
  end

  describe '#can_view_neighbourhood_by_id?' do
    let(:ward) { create(:riverside_ward) }
    let(:other_ward) { create(:oldtown_ward) }

    context 'when user is root' do
      let(:user) { create(:root_user) }

      it 'can view any neighbourhood' do
        expect(user.can_view_neighbourhood_by_id?(ward.id)).to be true
        expect(user.can_view_neighbourhood_by_id?(other_ward.id)).to be true
      end
    end

    context 'when user is neighbourhood admin' do
      let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

      it 'can view owned neighbourhood' do
        expect(user.can_view_neighbourhood_by_id?(ward.id)).to be true
      end

      it 'cannot view unowned neighbourhood' do
        expect(user.can_view_neighbourhood_by_id?(other_ward.id)).to be false
      end
    end
  end

  describe 'tag validation' do
    let(:user) { create(:user) }

    it 'allows Partnership tags' do
      partnership = create(:partnership_tag)
      user.tags << partnership
      expect(user).to be_valid
    end

    it 'rejects Category tags' do
      category = create(:category_tag)
      user.tags << category
      expect(user).not_to be_valid
      expect(user.errors[:tags]).to include('Can only be of type Partnership')
    end

    it 'rejects Facility tags' do
      facility = create(:facility_tag)
      user.tags << facility
      expect(user).not_to be_valid
      expect(user.errors[:tags]).to include('Can only be of type Partnership')
    end
  end

  describe 'password validation' do
    it 'requires password by default' do
      user = described_class.new(email: 'test@test.com', role: 'citizen')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it 'skips password validation when skip_password_validation is set' do
      user = described_class.new(email: 'test@test.com', role: 'citizen')
      user.skip_password_validation = true
      expect(user).to be_valid
    end
  end

  describe '#admin_roles' do
    it 'returns comma-separated list of admin roles' do
      user = create(:root_user)
      expect(user.admin_roles).to include('root')
    end

    it 'includes neighbourhood_admin when user has neighbourhoods' do
      user = create(:neighbourhood_admin)
      expect(user.admin_roles).to include('neighbourhood_admin')
    end

    it 'includes partner_admin when user has partners' do
      user = create(:partner_admin)
      expect(user.admin_roles).to include('partner_admin')
    end

    it 'includes partnership_admin when user has partnership tags' do
      user = create(:partnership_admin)
      expect(user.admin_roles).to include('partnership_admin')
    end
  end
end
