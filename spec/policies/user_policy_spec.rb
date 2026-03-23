# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject { described_class.new(current_user, target_user) }

  let(:target_user) { create(:user) }

  describe "for a citizen" do
    let(:current_user) { create(:citizen_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "for a root user" do
    let(:current_user) { create(:root_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for a partner admin" do
    let(:current_user) { create(:partner_admin) }

    context "viewing themselves" do
      let(:target_user) { current_user }

      it { is_expected.to permit_action(:update) }
    end

    context "viewing other users outside their scope" do
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "viewing users within their scope" do
      let(:partner) { current_user.partners.first }
      let(:target_user) { create(:user, partners: [partner]) }

      it { is_expected.to permit_action(:update) }
    end
  end

  describe "for a neighbourhood admin" do
    let(:ward) { create(:riverside_ward) }
    let(:current_user) { create(:neighbourhood_admin, neighbourhood: ward) }

    context "with partners in their neighbourhood" do
      let!(:partner_in_neighbourhood) do
        create(:partner, address: create(:address, neighbourhood: ward))
      end

      it { is_expected.to permit_action(:index) }
    end

    context "without partners in their neighbourhood" do
      it { is_expected.to forbid_action(:index) }
    end
  end

  describe "Scope" do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    describe "for root user" do
      let(:current_user) { create(:root_user) }

      it "returns all users" do
        scope = Pundit.policy_scope(current_user, User)
        expect(scope).to include(user1, user2, current_user)
      end
    end

    describe "for citizen" do
      let(:current_user) { create(:citizen_user) }

      it "returns no users" do
        scope = Pundit.policy_scope(current_user, User)
        expect(scope).to be_empty
      end
    end

    describe "for partner admin" do
      let(:current_user) { create(:partner_admin) }

      it "returns only themselves" do
        scope = Pundit.policy_scope(current_user, User)
        expect(scope).to include(current_user)
        expect(scope).not_to include(user1)
      end
    end

    describe "for neighbourhood admin" do
      let(:ward) { create(:riverside_ward) }
      let(:current_user) { create(:neighbourhood_admin, neighbourhood: ward) }

      it "always includes themselves" do
        scope = Pundit.policy_scope(current_user, User)
        expect(scope).to include(current_user)
      end

      it "includes users with partners in their neighbourhood" do
        partner_in_hood = create(:partner, address: create(:address, neighbourhood: ward))
        user_with_partner = create(:user, partners: [partner_in_hood])

        scope = Pundit.policy_scope(current_user, User)
        expect(scope).to include(user_with_partner)
      end

      it "excludes users with partners outside their neighbourhood" do
        scope = Pundit.policy_scope(current_user, User)
        expect(scope).not_to include(user1)
      end
    end
  end
end
