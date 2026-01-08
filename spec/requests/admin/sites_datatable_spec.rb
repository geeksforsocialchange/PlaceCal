# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sites Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable
  let(:datatable_columns) do
    [
      { data: :name, searchable: true, orderable: true },
      { data: :neighbourhoods },
      { data: :site_admin },
      { data: :updated_at, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 3)
    get admin_sites_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/sites.json" do
    context "basic functionality" do
      let!(:site) { create(:site, name: "Test Site") }

      it_behaves_like "datatable JSON structure"

      it "returns all sites in data array" do
        create(:site, name: "Another Site")
        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(2)
      end

      it "includes site name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test Site")
      end
    end

    context "search functionality" do
      let!(:matching_site) { create(:site, name: "Manchester PlaceCal") }
      let!(:non_matching_site) { create(:site, name: "London Events") }

      it_behaves_like "datatable search",
                      search_field: :name,
                      matching_value: "Manchester",
                      non_matching_value: "London"
    end

    context "sorting" do
      let!(:site_a) { create(:site, name: "Alpha Site") }
      let!(:site_z) { create(:site, name: "Zeta Site") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :name,
                      first_value: "Alpha",
                      last_value: "Zeta"
    end

    context "has_neighbourhoods filter" do
      let!(:neighbourhood) { create(:neighbourhood) }
      let!(:site_with_neighbourhood) do
        site = create(:site, name: "Site With Neighbourhood")
        site.neighbourhoods << neighbourhood
        site
      end
      let!(:site_without_neighbourhood) { create(:site, name: "Site Without Neighbourhood") }

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_neighbourhoods",
                      field: :name,
                      yes_value: "With Neighbourhood",
                      no_value: "Without Neighbourhood"
    end

    context "has_admin filter" do
      let!(:site_admin) { create(:user, first_name: "Admin", last_name: "User") }
      let!(:site_with_admin) { create(:site, name: "Site With Admin", site_admin: site_admin) }
      let!(:site_without_admin) { create(:site, name: "Site Without Admin") }

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_admin",
                      field: :name,
                      yes_value: "With Admin",
                      no_value: "Without Admin"
    end

    context "data rendering" do
      let!(:neighbourhood) { create(:neighbourhood) }
      let!(:site_admin) { create(:user, first_name: "Test", last_name: "Admin") }
      let!(:site) do
        site = create(:site, name: "Render Test", slug: "render-test", site_admin: site_admin)
        site.neighbourhoods << neighbourhood
        site
      end

      it "renders site name cell with slug subtitle" do
        datatable_request

        json = response.parsed_body
        site_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(site_data["name"]).to include("Render Test")
        expect(site_data["name"]).to include("render-test")
        expect(site_data["name"]).to include("href=")
      end

      it "renders neighbourhoods count cell" do
        datatable_request

        json = response.parsed_body
        site_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(site_data["neighbourhoods"]).to include("1")
        expect(site_data["neighbourhoods"]).to include("text-emerald-600")
      end

      it "renders site admin cell" do
        datatable_request

        json = response.parsed_body
        site_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(site_data["site_admin"]).to include("Test Admin")
      end

      it_behaves_like "datatable renders relative time", field: :updated_at
      it_behaves_like "datatable renders edit button"
    end
  end
end
