# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnersHelper, type: :helper do
  let(:root) { create(:root) }
  let(:partner) { create(:partner) }
  let(:neighbourhoods) do
    [
      create(:neighbourhood, name: "alpha"),
      create(:neighbourhood, name: "beta"),
      create(:neighbourhood, name: "cappa")
    ]
  end

  describe "#partner_service_area_text" do
    it "shows only one text correctly" do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq("alpha")
    end

    it "shows two texts correctly" do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])
      partner.service_areas.create(neighbourhood: neighbourhoods[1])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq("alpha and beta")
    end

    it "shows N texts correctly" do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])
      partner.service_areas.create(neighbourhood: neighbourhoods[1])
      partner.service_areas.create(neighbourhood: neighbourhoods[2])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq("alpha, beta and cappa")
    end
  end

  describe "#options_for_partner_users" do
    it "labels users by name and sorts them by it" do
      zed = create(:user, first_name: "Zed", email: "a@example.org")
      amy = create(:user, first_name: "amy", email: "z@example.org")
      expect(helper.options_for_partner_users(partner).map(&:last)).to eq([amy.id, zed.id])
      expect(helper.options_for_partner_users(partner)).to include([amy.display_name, amy.id])
    end
  end

  describe "#options_for_partner_partnerships" do
    let(:partnership_admin) { create(:neighbourhood_admin) }
    let(:partnership_tag) { create(:partnership) }
    let(:other_partnership_tag) { create(:partnership) }

    before do
      partnership_admin.tags << partnership_tag
    end

    context "as root user" do
      before do
        allow(helper).to receive(:current_user).and_return(root)
      end

      it "returns all allowed partnerships with no partner" do
        expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships).to eq(expected)
      end

      it "returns all allowed partnerships with partner" do
        expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships).to eq(expected)
      end
    end

    context "as partnership admin user" do
      before do
        allow(helper).to receive(:current_user).and_return(partnership_admin)
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(partnership_admin, Partnership)
        end
      end

      it "returns neighbourhood partnerships with no partner" do
        expected = [partnership_tag].map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships.sort).to eq(expected.sort)
      end

      it "returns neighbourhood partnerships with partner" do
        expected = [partnership_tag].map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships.sort).to eq(expected.sort)
      end
    end
  end

  describe "#options_for_parent_partner" do
    let(:user) { create(:partner_admin, partner:) }
    let(:editable) { create(:partner).tap { |p| user.partners << p } }

    before do
      allow(helper).to receive(:policy_scope) { |scope| Pundit.policy_scope!(user, scope) }
    end

    it "leaves out partners that are part of another partner" do
      nested = create(:partner, parent: editable).tap { |p| user.partners << p }

      expect(helper.options_for_parent_partner(partner)).to include([editable.name, editable.id])
      expect(helper.options_for_parent_partner(partner)).not_to include([nested.name, nested.id])
    end

    it "keeps the current parent listed when the user can't edit it" do
      outside_parent = create(:partner)
      partner.update!(parent: outside_parent)

      expect(helper.options_for_parent_partner(partner)).to include([outside_parent.name, outside_parent.id])
    end
  end
end
