# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Neighbourhoods Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable
  let(:datatable_columns) do
    [
      { data: :name, searchable: true, orderable: true },
      { data: :unit, orderable: true },
      { data: :hierarchy },
      { data: :partners_count, orderable: true },
      { data: :release_date, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 0, default_sort_dir: "asc")
    get admin_neighbourhoods_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/neighbourhoods.json" do
    context "basic functionality" do
      let!(:neighbourhood) { create(:neighbourhood, name: "Test Ward") }

      it_behaves_like "datatable JSON structure"

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

      it_behaves_like "datatable search",
                      search_field: :name,
                      matching_value: "Manchester",
                      non_matching_value: "London"
    end

    context "sorting" do
      let!(:neighbourhood_a) { create(:neighbourhood, name: "Alpha Ward") }
      let!(:neighbourhood_z) { create(:neighbourhood, name: "Zeta Ward") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :name,
                      first_value: "Alpha",
                      last_value: "Zeta"
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

      before { admin_user.neighbourhoods << neighbourhood }

      it "renders neighbourhood name cell with ID" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["name"]).to include("Render Test Ward")
        expect(neighbourhood_data["name"]).to include("##{neighbourhood.id}")
        expect(neighbourhood_data["name"]).to include("href=")
      end

      it "renders unit cell with colored badge" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["unit"]).to include("Ward")
        expect(neighbourhood_data["unit"]).to include("bg-violet-100")
      end

      it "renders hierarchy cell with parent info" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        # Hierarchy cell should contain the neighbourhood's path rendered as badges
        expect(neighbourhood_data["hierarchy"]).to include("Render Test Ward")
      end

      it "renders partners count with badge when partners exist" do
        # Create an address and force neighbourhood association (bypassing geocoding)
        address = create(:address)
        address.update_column(:neighbourhood_id, neighbourhood.id) # rubocop:disable Rails/SkipsModelValidations
        # Create partner and force address association
        partner = create(:partner)
        partner.update_column(:address_id, address.id) # rubocop:disable Rails/SkipsModelValidations
        # Refresh count (after_commit callbacks don't fire in transactional tests)
        neighbourhood.refresh_partners_count!
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["partners_count"]).to include("1")
        expect(neighbourhood_data["partners_count"]).to include("bg-emerald-100")
      end

      it "renders dash when no partners" do
        datatable_request

        json = response.parsed_body
        neighbourhood_data = json["data"].find { |d| d["name"].include?("Render Test Ward") }
        expect(neighbourhood_data["partners_count"]).to include("—")
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
        datatable_request("filter" => { "release" => "legacy" })

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
