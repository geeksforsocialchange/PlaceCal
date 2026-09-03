# frozen_string_literal: true

require "rails_helper"

RSpec.describe PagePolicy, type: :policy do
  subject(:policy) { described_class.new(user, page) }

  let(:site_admin) { create(:user) }
  let(:site) { create(:site, site_admin: site_admin) }
  let(:page) { create(:page, site: site) }

  describe "for a citizen" do
    let(:user) { create(:citizen_user) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "for a root user" do
    let(:user) { create(:root_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    it "may set the site" do
      expect(policy.permitted_attributes).to include(:site_id)
    end
  end

  describe "for an editor" do
    let(:user) { create(:editor_user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    it "may set the site" do
      expect(policy.permitted_attributes).to include(:site_id)
    end
  end

  describe "for the site's own admin" do
    let(:user) { site_admin }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }

    it "may not set the site" do
      expect(policy.permitted_attributes).not_to include(:site_id)
    end

    it "may edit the content attributes" do
      expect(policy.permitted_attributes)
        .to match_array(%i[title slug body position show_in_nav is_published])
    end
  end

  describe "for the admin of a different site" do
    let(:user) { create(:user) }

    before { create(:site, site_admin: user) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "Scope" do
    let!(:own_page) { create(:page, site: site) }
    let!(:other_page) { create(:page, site: create(:site)) }

    def resolved(user)
      described_class::Scope.new(user, Page).resolve
    end

    it "returns every page for root" do
      expect(resolved(create(:root_user))).to include(own_page, other_page)
    end

    it "returns every page for an editor" do
      expect(resolved(create(:editor_user))).to include(own_page, other_page)
    end

    it "returns only their own site's pages for a site admin" do
      result = resolved(site_admin)
      expect(result).to include(own_page)
      expect(result).not_to include(other_page)
    end

    it "returns nothing for a citizen" do
      expect(resolved(create(:citizen_user))).to be_empty
    end
  end
end
