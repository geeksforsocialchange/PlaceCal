# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventPolicy, type: :policy do
  subject { described_class.new(user, event) }

  let(:calendar) { create(:calendar) }
  let(:event) { create(:event, calendar:) }

  describe "for a root user" do
    let(:user) { create(:root_user) }

    it { is_expected.to permit_action(:show) }

    context "with an event from no calendar" do
      let(:calendar) { nil }

      it { is_expected.to permit_action(:show) }
    end
  end

  describe "for a partner admin" do
    let(:user) { create(:partner_admin) }

    context "on an event from a calendar they can edit" do
      let(:calendar) { create(:calendar, organiser: user.partners.first) }

      it { is_expected.to permit_action(:show) }
    end

    context "on an event from someone else's calendar" do
      it { is_expected.to forbid_action(:show) }
    end

    context "with an event from no calendar, organised by their own partner" do
      let(:event) { create(:event, calendar: nil, organiser: user.partners.first) }

      it { is_expected.to forbid_action(:show) }
    end
  end

  describe "for a citizen" do
    let(:user) { create(:citizen_user) }

    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:update) }
  end
end
