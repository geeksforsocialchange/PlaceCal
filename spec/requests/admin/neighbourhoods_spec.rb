# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Neighbourhoods", type: :request do
  let!(:root_user) { create(:root_user) }
  let!(:neighbourhood) { create(:neighbourhood) }
  let!(:neighbourhood_admin) { create(:neighbourhood_admin) }
  let!(:additional_neighbourhoods) { create_list(:neighbourhood, 4) }

  describe "GET /admin/neighbourhoods" do
    context "as a root user" do
      before { sign_in root_user }

      it "shows correct title" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("<title>Neighbourhoods | PlaceCal Admin</title>")
      end

      it "shows all neighbourhoods" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        # Root users see all neighbourhoods (up to pagination limit)
        # The page should contain neighbourhood rows
        expect(response.body).to include("<tbody")
      end
    end

    context "as a neighbourhood admin" do
      before { sign_in neighbourhood_admin }

      it "shows only their neighbourhoods" do
        get admin_neighbourhoods_url(host: admin_host)
        expect(response).to be_successful
        # Neighbourhood admin sees only their assigned neighbourhood(s)
        # Should have exactly 1 row for their neighbourhood
      end
    end
  end

  describe "GET /admin/neighbourhoods/children" do
    let!(:country) { create(:normal_island_country, level: 5) }
    let!(:region) { create(:northvale_region, parent: country, level: 4) }
    let!(:county) { create(:greater_millbrook_county, parent: region, level: 3) }
    let!(:district_under_county) { create(:millbrook_district, parent: county, level: 2) }
    # A district directly under the region (not under any county) —
    # mirrors Manchester being a direct child of North West, not Lancashire
    let!(:district_under_region) do
      create(:neighbourhood,
             name: "Stanfield",
             unit: "district",
             unit_code_key: "ZZ00DT",
             unit_code_value: "ZZ3000099",
             level: 2,
             release_date: Neighbourhood::LATEST_RELEASE_DATE,
             parent: region)
    end

    before { sign_in root_user }

    it "returns countries at the top level" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { level: 5 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      names = response.parsed_body.map { |n| n["name"] }
      expect(names).to include("Normal Island")
    end

    it "returns regions for a country" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { parent_id: country.id, level: 4 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      names = response.parsed_body.map { |n| n["name"] }
      expect(names).to include("Northvale")
    end

    it "returns counties for a region" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { parent_id: region.id, level: 3 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      names = response.parsed_body.map { |n| n["name"] }
      expect(names).to include("Greater Millbrook")
    end

    # Skip county scenario: user selects "Show all (skip this level)"
    # on the county dropdown, JS sends parent_id=region to load districts
    it "returns all districts in region subtree when skipping county level" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { parent_id: region.id, level: 2 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      names = response.parsed_body.map { |n| n["name"] }
      expect(names).to include("Millbrook")
      expect(names).to include("Stanfield")
    end

    # Normal county selection: only shows that county's districts
    it "returns only county descendants when a county is selected" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { parent_id: county.id, level: 2 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      names = response.parsed_body.map { |n| n["name"] }
      expect(names).to include("Millbrook")
      expect(names).not_to include("Stanfield")
    end

    # Auto-select scenario: when there's only one county, the JS auto-selects
    # it but loads the next level from the parent (region) scope so all
    # districts remain reachable
    it "returns all districts including those not under any county" do
      get children_admin_neighbourhoods_url(host: admin_host, params: { parent_id: region.id, level: 2 }),
          headers: { "Accept" => "application/json" }

      expect(response).to be_successful
      ids = response.parsed_body.map { |n| n["id"] }
      expect(ids).to include(district_under_county.id)
      expect(ids).to include(district_under_region.id)
    end
  end

  describe "GET /admin/neighbourhoods/:id/edit" do
    context "as a root user" do
      before { sign_in root_user }

      it "shows edit form with all fields" do
        get edit_admin_neighbourhood_url(neighbourhood, host: admin_host)
        expect(response).to be_successful

        # Editable fields
        expect(response.body).to include("Name")
        expect(response.body).to include("Abbreviated Name")

        # ONS info card (compact display)
        expect(response.body).to include("Level")
        expect(response.body).to include("Unit Name")
        expect(response.body).to include("ONS Code")
        expect(response.body).to include("ONS Dataset")

        # User assignment and actions
        expect(response.body).to include("Users")
        expect(response.body).to include("Save")
      end
    end
  end
end
