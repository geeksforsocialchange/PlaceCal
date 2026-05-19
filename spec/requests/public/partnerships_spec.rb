# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Partnerships", type: :request do
  let!(:default_site) { create(:default_site) }

  let!(:partnerships) do
    Array.new(3) do |i|
      create(:site, slug: "partnership-#{i}", is_published: true, name: "Test Partnership #{i}")
    end
  end

  describe "GET /partnerships (directory)" do
    it "returns successful response" do
      get partnerships_url(host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partnership names" do
      get partnerships_url(host: "lvh.me")
      partnerships.each do |partnership|
        expect(response.body).to include(partnership.name)
      end
    end

    it "sets page title" do
      get partnerships_url(host: "lvh.me")
      expect(response.body).to include("<title>Partnerships")
    end

    it "excludes default-site from listings" do
      get partnerships_url(host: "lvh.me")
      expect(response.body).not_to include(">#{default_site.name}<")
    end

    context "with search query" do
      it "returns successful response" do
        get partnerships_url(host: "lvh.me", params: { q: partnerships.first.name })
        expect(response).to be_successful
      end
    end

    context "with no results" do
      it "shows empty state" do
        get partnerships_url(host: "lvh.me", params: { q: "nonexistent-xyz" })
        expect(response).to be_successful
        expect(response.body).to include("No partnerships found")
      end
    end
  end

  describe "GET /partnerships/:id (directory)" do
    let(:partnership) { partnerships.first }

    it "returns successful response" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partnership name" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include(partnership.name)
    end

    it "shows breadcrumb navigation" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include("Partnerships")
      expect(response.body).to include(partnership.name)
    end

    it "shows visit button" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include("#{partnership.slug}.placecal.org")
    end

    context "with partners in neighbourhood" do
      let(:ward) { create(:riverside_ward) }

      before do
        partnership.neighbourhoods << ward
        3.times do
          create(:partner, address: create(:address, neighbourhood: ward))
        end
      end

      it "displays partner count" do
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).to include("3 partners")
      end
    end
  end
end
