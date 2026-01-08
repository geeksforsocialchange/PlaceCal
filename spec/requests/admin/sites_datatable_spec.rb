# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Sites Datatable JSON API", type: :request do
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
        "1" => { "data" => "neighbourhoods", "name" => "neighbourhoods", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "site_admin", "name" => "site_admin", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "updated_at", "name" => "updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "3", "dir" => "desc" } }
    }
    get admin_sites_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/sites.json" do
    context "basic functionality" do
      let!(:site) { create(:site, name: "Test Site") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("draw")
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

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

      it "filters sites by search term" do
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
      let!(:site_a) { create(:site, name: "Alpha Site") }
      let!(:site_z) { create(:site, name: "Zeta Site") }

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

    context "has_neighbourhoods filter" do
      let!(:neighbourhood) { create(:neighbourhood) }
      let!(:site_with_neighbourhood) do
        site = create(:site, name: "Site With Neighbourhood")
        site.neighbourhoods << neighbourhood
        site
      end
      let!(:site_without_neighbourhood) { create(:site, name: "Site Without Neighbourhood") }

      it "filters sites with neighbourhoods" do
        datatable_request("filter" => { "has_neighbourhoods" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("With Neighbourhood")
        expect(names.join).not_to include("Without Neighbourhood")
      end

      it "filters sites without neighbourhoods" do
        datatable_request("filter" => { "has_neighbourhoods" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Without Neighbourhood")
        expect(names.join).not_to include("With Neighbourhood")
      end
    end

    context "has_admin filter" do
      let!(:site_admin) { create(:user, first_name: "Admin", last_name: "User") }
      let!(:site_with_admin) { create(:site, name: "Site With Admin", site_admin: site_admin) }
      let!(:site_without_admin) { create(:site, name: "Site Without Admin") }

      it "filters sites with admin" do
        datatable_request("filter" => { "has_admin" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("With Admin")
        expect(names.join).not_to include("Without Admin")
      end

      it "filters sites without admin" do
        datatable_request("filter" => { "has_admin" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Without Admin")
        expect(names.join).not_to include("With Admin")
      end
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

      it "renders updated_at as relative time" do
        datatable_request

        json = response.parsed_body
        site_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(site_data["updated_at"]).to include("Today")
      end

      it "renders actions with edit button" do
        datatable_request

        json = response.parsed_body
        site_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(site_data["actions"]).to include("Edit")
        expect(site_data["actions"]).to include("href=")
      end
    end
  end
end
