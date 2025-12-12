# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticlePolicy, type: :policy do
  subject { described_class.new(user, article) }

  let(:partner) { create(:partner) }
  let(:article) { create(:article, partners: [partner]) }

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
    # Partner admins with partners can access article section
    # show?/update? delegate to index?, so they can access any article
    # (the Scope controls what they see in lists)
    context 'on their partners article' do
      let(:user) { create(:partner_admin) }
      let(:article) { create(:article, partners: [user.partners.first]) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:create) }
      it { is_expected.to permit_action(:update) }
    end

    context 'on another partners article' do
      let(:user) { create(:partner_admin) }
      let(:other_partner) { create(:partner) }
      let(:article) { create(:article, partners: [other_partner]) }

      # Can access index (has partners)
      it { is_expected.to permit_action(:index) }
      # show?/update? just return index?, so permitted
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
    end
  end

  describe 'for a neighbourhood admin' do
    let(:ward) { create(:riverside_ward) }
    let(:user) { create(:neighbourhood_admin, neighbourhood: ward) }

    context 'on article for partner in their neighbourhood' do
      let(:address) { create(:address, neighbourhood: ward) }
      let(:partner) { create(:partner, address: address) }
      let(:article) { create(:article, partners: [partner]) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:update) }
    end
  end
end
