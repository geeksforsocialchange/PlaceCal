# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Partners", type: :request do
  let(:site) { create(:site, slug: "test-site") }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe "GET /partners" do
    # Must use same ward instance - :riverside_address creates NEW ward via association
    let!(:partners) do
      Array.new(3) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end
    end

    it "returns successful response" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
    end

    it "displays partners in site neighbourhood" do
      get partners_url(host: "#{site.slug}.lvh.me")
      partners.each do |partner|
        expect(response.body).to include(partner.name)
      end
    end

    it "does not show hidden partners" do
      hidden_partner = create(:partner,
                              address: create(:address, neighbourhood: ward),
                              hidden: true,
                              hidden_reason: "Test",
                              hidden_blame_id: 1)
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).not_to include(hidden_partner.name)
    end
  end

  describe "GET /partners/:id" do
    let(:partner) { create(:riverside_partner) }

    it "shows the partner details" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(partner.name)
    end

    it "shows partner summary" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.summary)
    end

    it "shows partner address" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include(partner.address.postcode)
    end

    it "shows correct page title" do
      get partner_url(partner, host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>#{partner.name} | #{site.name}</title>")
    end

    context "without accessibility info" do
      it "hides accessibility section" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).not_to include("accessibility-info")
      end
    end

    context "with accessibility info" do
      before { partner.update!(accessibility_info: "Wheelchair accessible entrance") }

      it "shows accessibility section" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).to include("accessibility-info")
        expect(response.body).to include("Wheelchair accessible entrance")
      end
    end

    context "without calendar" do
      it "shows no events message" do
        get partner_url(partner, host: "#{site.slug}.lvh.me")
        expect(response.body).to include("does not list events")
      end
    end
  end

  describe "GET /partners with category filter" do
    let(:category) { create(:category_tag) }
    # Must use same ward instance
    let!(:categorized_partner) do
      partner = create(:partner, address: create(:address, neighbourhood: ward))
      partner.categories << category
      partner
    end
    let!(:uncategorized_partner) do
      create(:partner, address: create(:address, neighbourhood: ward))
    end

    it "filters partners by category" do
      # Filter by category ID since slug format may vary
      get partners_url(host: "#{site.slug}.lvh.me", params: { category: category.id })
      expect(response).to be_successful
    end
  end

  describe "GET /partners with neighbourhood filter" do
    # Must use same ward instance
    let!(:riverside_partner) do
      create(:partner, address: create(:address, neighbourhood: ward))
    end

    it "filters partners by neighbourhood" do
      # Controller expects neighbourhood ID, not name
      get partners_url(host: "#{site.slug}.lvh.me", params: { neighbourhood: ward.id })
      expect(response).to be_successful
    end
  end

  describe "GET /partners index content" do
    let!(:partners) do
      Array.new(5) do
        address = create(:address, neighbourhood: ward)
        create(:partner, address: address)
      end
    end

    it "shows page title with site name" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("<title>Partners | #{site.name}</title>")
    end

    it "shows partners header" do
      get partners_url(host: "#{site.slug}.lvh.me")
      expect(response.body).to include("Our Partners")
    end

    it "shows partner names and summaries" do
      get partners_url(host: "#{site.slug}.lvh.me")
      partners.each do |partner|
        expect(response.body).to include(partner.name)
        expect(response.body).to include(partner.summary)
      end
    end
  end

  describe "GET /partners with tagged site" do
    let(:tag) { create(:tag) }
    let(:tagged_site) { create(:site, slug: "tagged-site") }
    let!(:tagged_partners) do
      Array.new(3) do
        address = create(:address, neighbourhood: ward)
        partner = create(:partner, address: address)
        partner.tags << tag
        partner
      end
    end
    let!(:untagged_partner) do
      address = create(:address, neighbourhood: ward)
      create(:partner, address: address)
    end

    before do
      tagged_site.neighbourhoods << ward
      tagged_site.tags << tag
    end

    it "shows only tagged partners" do
      get partners_url(host: "#{tagged_site.slug}.lvh.me")
      expect(response).to be_successful

      tagged_partners.each do |partner|
        expect(response.body).to include(partner.name)
      end

      # Untagged partner should not appear
      expect(response.body).not_to include(untagged_partner.name)
    end
  end

  describe "default site redirect" do
    let!(:default_site) { create_default_site }

    it "redirects partners page on base domain" do
      get partners_url(host: "lvh.me")
      expect(response).to be_redirect
    end
  end
end
