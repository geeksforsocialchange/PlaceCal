# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarPolicy, type: :policy do
  subject { described_class.new(user, calendar) }

  let(:partner) { create(:partner) }
  let(:calendar) do
    cal = build(:calendar, partner: partner)
    allow(cal).to receive(:check_source_reachable)
    cal.save!
    cal
  end

  describe 'for a citizen' do
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
    context 'on their partners calendar' do
      let(:user) { create(:partner_admin) }
      let(:partner) { user.partners.first }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
    end

    context 'on another partners calendar' do
      let(:user) { create(:partner_admin) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:update) }
    end
  end

  describe 'for a neighbourhood admin' do
    let(:ward) { create(:riverside_ward) }
    let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

    context 'on calendar for partner in their neighbourhood' do
      let(:address) { create(:address, neighbourhood: ward) }
      let(:partner) { create(:partner, address: address) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
    end
  end

  describe 'Scope' do
    let!(:calendar1) do
      cal = build(:calendar)
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end
    let!(:calendar2) do
      cal = build(:calendar)
      allow(cal).to receive(:check_source_reachable)
      cal.save!
      cal
    end

    describe 'for root user' do
      let(:user) { create(:root_user) }

      it 'returns all calendars' do
        scope = Pundit.policy_scope(user, Calendar)
        expect(scope).to include(calendar1, calendar2)
      end
    end

    describe 'for citizen' do
      let(:user) { create(:citizen_user) }

      it 'returns no calendars' do
        scope = Pundit.policy_scope(user, Calendar)
        expect(scope).to be_empty
      end
    end
  end
end
