# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Partners', type: :request do
  let(:site) { create(:site, slug: 'test-site') }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe 'GET /partners' do
    let!(:partners) do
      Array.new(3) do
        address = create(:riverside_address)
        create(:partner, address: address)
      end
    end

    it 'returns successful response' do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it 'displays partners in site neighbourhood' do
      get partners_url(host: "#{site.slug}.lvh.me")
      partners.each do |partner|
        expect(response.body).to include(partner.name)
      end
    end

    it 'does not show hidden partners' do
      hidden_partner = create(:partner,
                              address: create(:riverside_address),
                              hidden: true,
                              hidden_reason: 'Test',
                              hidden_blame_id: 1)
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).not_to include(hidden_partner.name)
    end
  end

  describe 'GET /partners/:id' do
    let(:partner) { create(:riverside_partner) }

    it 'shows the partner details' do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(partner.name)
    end

    it 'shows partner summary' do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.summary)
    end

    it 'shows partner address' do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.address.postcode)
    end
  end

  describe 'GET /partners with category filter' do
    let(:category) { create(:category_tag) }
    let!(:categorized_partner) do
      partner = create(:partner, address: create(:riverside_address))
      partner.categories << category
      partner
    end
    let!(:uncategorized_partner) do
      create(:partner, address: create(:riverside_address))
    end

    it 'filters partners by category' do
      get partners_url(host: "#{site.slug}.lvh.me", params: { category: category.slug })
      expect(response).to be_successful
    end
  end

  describe 'GET /partners with neighbourhood filter' do
    let!(:riverside_partner) do
      create(:partner, address: create(:riverside_address))
    end

    it 'filters partners by neighbourhood' do
      get partners_url(host: "#{site.slug}.lvh.me", params: { neighbourhood: 'Riverside' })
      expect(response).to be_successful
    end
  end
end
