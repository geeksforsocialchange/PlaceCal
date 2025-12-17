# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerPolicy, type: :policy do
  subject { described_class.new(user, partner) }

  let(:partner) { create(:partner) }

  describe 'for a citizen (no admin rights)' do
    let(:user) { create(:citizen_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe 'for a root user' do
    let(:user) { create(:root_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe 'for a partner admin' do
    let(:user) { create(:partner_admin) }
    let(:partner) { user.partners.first }
    let(:other_partner) { create(:partner) }

    context 'on their own partner' do
      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to forbid_action(:create) }
      # NOTE: partner_admin CAN destroy their own partner per current policy
      it { is_expected.to permit_action(:destroy) }
    end

    context 'on another partner' do
      subject { described_class.new(user, other_partner) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  describe 'for a neighbourhood admin' do
    let(:ward) { create(:riverside_ward) }
    let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }
    let(:partner_in_neighbourhood) do
      address = create(:address, neighbourhood: ward)
      create(:partner, address: address)
    end
    let(:partner_outside_neighbourhood) do
      address = create(:oldtown_address)
      create(:partner, address: address)
    end

    context 'on a partner in their neighbourhood' do
      subject { described_class.new(user, partner_in_neighbourhood) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
    end

    context 'on a partner outside their neighbourhood' do
      subject { described_class.new(user, partner_outside_neighbourhood) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'for a partnership admin' do
    let(:ward) { create(:riverside_ward) }
    let(:partnership_tag) { create(:partnership_tag) }
    let(:user) do
      user = create(:neighbourhood_admin, neighbourhood: ward)
      user.tags << partnership_tag
      user
    end
    let(:partner_in_partnership) do
      address = create(:address, neighbourhood: ward)
      partner = create(:partner, address: address)
      partner.tags << partnership_tag
      partner
    end
    let(:partner_not_in_partnership) do
      address = create(:address, neighbourhood: ward)
      create(:partner, address: address)
    end

    context 'on a partner in their partnership' do
      subject { described_class.new(user, partner_in_partnership) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
    end

    context 'on a partner not in their partnership' do
      subject { described_class.new(user, partner_not_in_partnership) }

      it { is_expected.to permit_action(:index) }
      # NOTE: partnership_admin can only see partners in their partnership,
      # even if also a neighbourhood_admin for that area
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe 'Scope' do
    let!(:partner1) { create(:partner) }
    let!(:partner2) { create(:partner) }

    describe 'for root user' do
      let(:user) { create(:root_user) }

      it 'returns all partners' do
        scope = Pundit.policy_scope(user, Partner)
        expect(scope).to include(partner1, partner2)
      end
    end

    describe 'for citizen' do
      let(:user) { create(:citizen_user) }

      it 'returns no partners' do
        scope = Pundit.policy_scope(user, Partner)
        expect(scope).to be_empty
      end
    end

    describe 'for partner admin' do
      let(:user) { create(:partner_admin) }

      it 'returns only their partners' do
        scope = Pundit.policy_scope(user, Partner)
        expect(scope).to include(user.partners.first)
        expect(scope).not_to include(partner1)
      end
    end
  end
end
