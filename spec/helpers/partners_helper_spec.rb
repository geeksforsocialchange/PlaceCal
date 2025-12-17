# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnersHelper, type: :helper do
  let(:root) { create(:root) }
  let(:partner) { create(:partner) }
  let(:neighbourhoods) do
    [
      create(:neighbourhood, name: 'alpha'),
      create(:neighbourhood, name: 'beta'),
      create(:neighbourhood, name: 'cappa')
    ]
  end

  describe '#partner_service_area_text' do
    it 'shows only one text correctly' do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq('alpha')
    end

    it 'shows two texts correctly' do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])
      partner.service_areas.create(neighbourhood: neighbourhoods[1])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq('alpha and beta')
    end

    it 'shows N texts correctly' do
      partner.service_areas.create(neighbourhood: neighbourhoods[0])
      partner.service_areas.create(neighbourhood: neighbourhoods[1])
      partner.service_areas.create(neighbourhood: neighbourhoods[2])

      output = helper.partner_service_area_text(partner)

      expect(output).to eq('alpha, beta and cappa')
    end
  end

  describe '#options_for_partner_partnerships' do
    let(:partnership_admin) { create(:neighbourhood_admin) }
    let(:partnership_tag) { create(:partnership) }
    let(:other_partnership_tag) { create(:partnership) }

    before do
      partnership_admin.tags << partnership_tag
    end

    context 'as root user' do
      it 'returns all allowed partnerships with no partner' do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(root, Partnership)
        end

        expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships).to eq(expected)
      end

      it 'returns all allowed partnerships with partner' do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(root, Partnership)
        end

        expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships).to eq(expected)
      end
    end

    context 'as partnership admin user' do
      it 'returns neighbourhood partnerships with no partner' do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(partnership_admin, Partnership)
        end

        expected = [partnership_tag].map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships.sort).to eq(expected.sort)
      end

      it 'returns neighbourhood partnerships with partner' do
        allow(helper).to receive(:policy_scope) do |_scope|
          Pundit.policy_scope!(partnership_admin, Partnership)
        end

        expected = [partnership_tag].map { |r| [r.name, r.id] }

        expect(helper.options_for_partner_partnerships.sort).to eq(expected.sort)
      end
    end
  end
end
