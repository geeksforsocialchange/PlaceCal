# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  let(:root) { create(:root) }
  let(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let(:partner_admin) { create(:partner_admin) }
  let(:partner) { create(:partner) }
  let(:partner_in_neighbourhood) do
    p = create(:partner)
    p.address.neighbourhood = neighbourhood_admin.neighbourhoods.first
    p.save!
    p
  end
  let(:partner_servicing_neighbourhood) do
    p = create(:partner)
    p.service_area_neighbourhoods << neighbourhood_admin.neighbourhoods.first
    p.save!
    p
  end

  describe "#options_for_partners" do
    context "as root user" do
      before do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(root, Partner)
        end
      end

      it "returns all allowed partners with no user" do
        expected = Partner.order(:name).pluck(:name, :id)

        expect(helper.options_for_partners).to eq(expected)
      end

      it "returns all allowed partners with user" do
        expected = Partner.order(:name).pluck(:name, :id)

        expect(helper.options_for_partners(neighbourhood_admin)).to eq(expected)
      end
    end

    context "as neighbourhood admin" do
      before do
        # Force creation of partners
        partner_in_neighbourhood
        partner_servicing_neighbourhood

        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(neighbourhood_admin, Partner)
        end
      end

      it "returns neighbourhood partners with no user" do
        expected = [partner_in_neighbourhood, partner_servicing_neighbourhood].pluck(:name, :id)

        expect(helper.options_for_partners.sort).to eq(expected.sort)
      end

      it "returns neighbourhood partners with user" do
        expected = [partner_in_neighbourhood, partner_servicing_neighbourhood].pluck(:name, :id)

        expect(helper.options_for_partners(neighbourhood_admin).sort).to eq(expected.sort)
      end

      it "returns neighbourhood partners & partners owned by user for partner owning user" do
        expected = [
          partner_in_neighbourhood,
          partner_servicing_neighbourhood,
          partner_admin.partners.first
        ].pluck(:name, :id)

        expect(helper.options_for_partners(partner_admin).sort).to eq(expected.sort)
      end
    end
  end

  describe "#permitted_options_for_partners" do
    context "as neighbourhood admin" do
      before do
        # Force creation
        partner_in_neighbourhood
        partner_servicing_neighbourhood

        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(neighbourhood_admin, Partner)
        end
      end

      it "only shows neighbourhood partners" do
        expected = [partner_in_neighbourhood, partner_servicing_neighbourhood].pluck(:id)

        expect(helper.permitted_options_for_partners.sort).to eq(expected.sort)
      end
    end

    context "as root admin" do
      before do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(root, Partner)
        end
      end

      it "shows all partners" do
        expected = Partner.all.pluck(:id)

        expect(helper.permitted_options_for_partners.sort).to eq(expected.sort)
      end
    end
  end
end
