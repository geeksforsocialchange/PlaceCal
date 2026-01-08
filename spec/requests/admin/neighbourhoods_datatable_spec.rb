# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Neighbourhoods Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  let(:admin_host) { "admin.lvh.me" }

  before { sign_in admin_user }

  # Helper to make datatable requests with proper params
  def datatable_request(params = {})
    base_params = {
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => {
        "0" => { "data" => "name", "name" => "name", "searchable" => "true", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "1" => { "data" => "unit", "name" => "unit", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "parent_name", "name" => "parent_name", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "unit_code_value", "name" => "unit_code_value", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "release_date", "name" => "release_date", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "0", "dir" => "asc" } }
    }
    get admin_neighbourhoods_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/neighbourhoods.json" do
    context "basic functionality" do
      let!(:neighbourhood) { create(:neighbourhood, name: "Test Ward") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("draw")
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

      it "returns all neighbourhoods in data array" do
        create(:neighbourhood, name: "Another Ward")

        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(2)
      end

      it "includes neighbourhood name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test Ward")
      end
    end

    context "search functionality" do
      let!(:matching_neighbourhood) { create(:neighbourhood, name: "Manchester Central") }
      let!(:non_matching_neighbourhood) { create(:neighbourhood, name: "London West") }

      it "filters neighbourhoods by search term" do
        datatable_request("search" => { "value" => "Manchester" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Manchester")
        expect(names.join).not_to include("London")
      end

      it "search is case insensitive" do
        datatable_request("search" => { "value" => "MANCHESTER" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Manchester")
      end
    end

    context "sorting" do
      let!(:neighbourhood_a) { create(:neighbourhood, name: "Alpha Ward") }
      let!(:neighbourhood_z) { create(:neighbourhood, name: "Zeta Ward") }

      it "sorts by name ascending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "asc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to match(/Alpha.*Zeta/m)
      end

      it "sorts by name descending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "desc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to match(/Zeta.*Alpha/m)
      end
    end

    context "unit filter" do
      let!(:ward) { create(:neighbourhood, name: "Test Ward", unit: "ward") }
      let!(:district) { create(:neighbourhood, name: "Test District", unit: "district") }
      let!(:county) { create(:neighbourhood, name: "Test County", unit: "county") }

      it "filters by ward unit" do
        datatable_request("filter" => { "unit" => "ward" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test Ward")
        expect(names.join).not_to include("Test District")
        expect(names.join).not_to include("Test County")
      end

      it "filters by district unit" do
        datatable_request("filter" => { "unit" => "district" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test District")
        expect(names.join).not_to include("Test Ward")
      end
    end

    context "release filter" do
      let(:current_date) { Neighbourhood::LATEST_RELEASE_DATE }
      let(:legacy_date) { Date.new(2020, 1, 1) }
      let!(:current_neighbourhood) { create(:neighbourhood, name: "Current Neighbourhood", release_date: current_date) }
      let!(:legacy_neighbourhood) { create(:neighbourhood, name: "Legacy Neighbourhood", release_date: legacy_date) }

      it "filters current neighbourhoods" do
        datatable_request("filter" => { "release" => "current" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Current Neighbourhood")
        expect(names.join).not_to include("Legacy Neighbourhood")
      end

      it "filters legacy neighbourhoods" do
        datatable_request("filter" => { "release" => "legacy" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Legacy Neighbourhood")
        expect(names.join).not_to include("Current Neighbourhood")
      end
    end

    context "data rendering" do
      let(:current_date) { Neighbourhood::LATEST_RELEASE_DATE }
      let!(:neighbourhood) do
        create(:neighbourhood,
               name: "Render Test Ward",
               unit: "ward",
               unit_name: "Electoral Ward",
               parent_name: "Manchester",
               unit_code_value: "E05012345",
               release_date: current_date)
      end

      before do
        admin_user.neighbourhoods << neighbourhood
      end

      it "renders neighbourhood name cell with unit subtitle" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["name"]).to include("Render Test Ward")
        expect(neighbourhood_data["name"]).to include("Electoral Ward")
        expect(neighbourhood_data["name"]).to include("href=")
      end

      it "renders unit cell with colored badge" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["unit"]).to include("Ward")
        expect(neighbourhood_data["unit"]).to include("bg-blue-100")
      end

      it "renders parent cell" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["parent_name"]).to include("Manchester")
      end

      it "renders unit code cell in monospace" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["unit_code_value"]).to include("E05012345")
        expect(neighbourhood_data["unit_code_value"]).to include("font-mono")
      end

      it "renders release date with Current badge" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["release_date"]).to include("Current")
        expect(neighbourhood_data["release_date"]).to include("bg-emerald-100")
      end

      it "renders release date with Legacy badge for old releases" do
        neighbourhood.update!(release_date: Date.new(2020, 1, 1))
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["release_date"]).to include("Legacy")
        expect(neighbourhood_data["release_date"]).to include("bg-gray-100")
      end

      it "renders actions with view button for permitted users" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["actions"]).to include("View")
        expect(neighbourhood_data["actions"]).to include("href=")
      end
    end
  end
end
