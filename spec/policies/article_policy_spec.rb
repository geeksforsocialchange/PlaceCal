# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArticlePolicy, type: :policy do
  subject(:policy) { described_class.new(user, article) }

  let(:partner) { create(:partner) }
  let(:article) { create(:article, partners: [partner]) }

  describe "for a citizen" do
    let(:user) { create(:citizen_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "for a root user" do
    let(:user) { create(:root_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  describe "for an editor" do
    # Regression coverage for issue #2045 — editors manage all news articles
    let(:user) { create(:editor_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    it "has no disabled fields" do
      expect(policy.disabled_fields).to be_empty
    end

    describe "scope" do
      it "resolves every article, including other partners' ones" do
        with_partner = article
        without_partner = create(:article)

        resolved = described_class::Scope.new(user, Article).resolve
        expect(resolved).to contain_exactly(with_partner, without_partner)
      end
    end
  end

  describe "for a partner admin" do
    context "on their partners article" do
      let(:user) { create(:partner_admin) }
      let(:article) { create(:article, partners: [user.partners.first]) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "on an article shared between their partner and another" do
      let(:user) { create(:partner_admin) }
      let(:article) { create(:article, partners: [user.partners.first, create(:partner)]) }

      it { is_expected.to permit_action(:update) }
    end

    context "on another partners article" do
      let(:user) { create(:partner_admin) }
      let(:other_partner) { create(:partner) }
      let(:article) { create(:article, partners: [other_partner]) }

      # Can access the section (has partners), but not this record
      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context "when creating an article for another partner" do
      let(:user) { create(:partner_admin) }
      let(:article) { Article.new(partners: [create(:partner)]) }

      it { is_expected.to forbid_action(:create) }
    end

    context "when creating an article with no partners yet" do
      # An empty partner list must not block opening/submitting the form —
      # the controller enforces the at-least-one-partner rule with a
      # friendlier validation error than a 403.
      let(:user) { create(:partner_admin) }
      let(:article) { Article.new }

      it { is_expected.to permit_action(:new) }
      it { is_expected.to permit_action(:create) }
    end
  end

  describe "for a neighbourhood admin" do
    let(:ward) { create(:riverside_ward) }
    let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

    context "on article for partner in their neighbourhood" do
      let(:address) { create(:address, neighbourhood: ward) }
      let(:partner) { create(:partner, address: address) }
      let(:article) { create(:article, partners: [partner]) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "on article for partner with only a service area in their patch" do
      let(:partner) do
        create(:mobile_partner,
               address: create(:address, neighbourhood: create(:oldtown_ward)),
               service_area_wards: [ward])
      end
      let(:article) { create(:article, partners: [partner]) }

      it { is_expected.to permit_action(:update) }
    end

    context "on article for partner outside their patch" do
      let(:partner) { create(:partner, address: create(:address, neighbourhood: create(:oldtown_ward))) }
      let(:article) { create(:article, partners: [partner]) }

      # A partner in their own patch, so index? passes and these prove the
      # per-record ownership check rather than the section litmus test
      before { create(:partner, address: create(:address, neighbourhood: ward)) }

      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
