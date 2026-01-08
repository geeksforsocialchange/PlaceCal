# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tags Datatable JSON API", type: :request do
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
        "1" => { "data" => "type", "name" => "type", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "description", "name" => "description", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "system_tag", "name" => "system_tag", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "partners_count", "name" => "partners_count", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "updated_at", "name" => "updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "5", "dir" => "desc" } }
    }
    get admin_tags_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/tags.json" do
    context "basic functionality" do
      let!(:tag) { create(:tag, name: "Test Tag") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("draw")
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

      it "returns all tags in data array" do
        create(:tag, name: "Another Tag")

        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(2)
      end

      it "includes tag name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test Tag")
      end
    end

    context "search functionality" do
      let!(:matching_tag) { create(:tag, name: "Environment") }
      let!(:non_matching_tag) { create(:tag, name: "Sports") }

      it "filters tags by search term" do
        datatable_request("search" => { "value" => "Environment" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Environment")
        expect(names.join).not_to include("Sports")
      end

      it "search is case insensitive" do
        datatable_request("search" => { "value" => "ENVIRONMENT" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Environment")
      end
    end

    context "sorting" do
      let!(:tag_a) { create(:tag, name: "Alpha Tag") }
      let!(:tag_z) { create(:tag, name: "Zeta Tag") }

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

    context "type filter" do
      let!(:category_tag) { create(:category, name: "Category Tag") }
      let!(:partnership_tag) { create(:partnership, name: "Partnership Tag") }
      let!(:facility_tag) { create(:facility, name: "Facility Tag") }

      it "filters by Category type" do
        datatable_request("filter" => { "type" => "Category" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Category Tag")
        expect(names.join).not_to include("Partnership Tag")
        expect(names.join).not_to include("Facility Tag")
      end

      it "filters by Partnership type" do
        datatable_request("filter" => { "type" => "Partnership" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Partnership Tag")
        expect(names.join).not_to include("Category Tag")
      end

      it "filters by Facility type" do
        datatable_request("filter" => { "type" => "Facility" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Facility Tag")
        expect(names.join).not_to include("Category Tag")
      end
    end

    context "system_tag filter" do
      let!(:system_tag) { create(:tag, name: "System Tag", system_tag: true) }
      let!(:user_tag) { create(:tag, name: "User Tag", system_tag: false) }

      it "filters system tags" do
        datatable_request("filter" => { "system_tag" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("System Tag")
        expect(names.join).not_to include("User Tag")
      end

      it "filters user-created tags" do
        datatable_request("filter" => { "system_tag" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("User Tag")
        expect(names.join).not_to include("System Tag")
      end
    end

    context "has_partners filter" do
      let!(:partner) { create(:partner) }
      let!(:tag_with_partners) do
        tag = create(:tag, name: "Tag With Partners")
        tag.partners << partner
        tag
      end
      let!(:tag_without_partners) { create(:tag, name: "Tag Without Partners") }

      it "filters tags with partners" do
        datatable_request("filter" => { "has_partners" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("With Partners")
        expect(names.join).not_to include("Without Partners")
      end

      it "filters tags without partners" do
        datatable_request("filter" => { "has_partners" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Without Partners")
        expect(names.join).not_to include("With Partners")
      end
    end

    context "data rendering" do
      let!(:partner) { create(:partner) }
      let!(:tag) do
        tag = create(:category, name: "Render Test", description: "A test description for this tag")
        tag.partners << partner
        tag
      end

      it "renders tag name cell with slug subtitle" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["name"]).to include("Render Test")
        expect(tag_data["name"]).to include("render-test")
        expect(tag_data["name"]).to include("href=")
      end

      it "renders type cell with colored badge" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["type"]).to include("Category")
        expect(tag_data["type"]).to include("bg-blue-100")
      end

      it "renders description cell" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["description"]).to include("A test description")
      end

      it "renders partners count cell" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["partners_count"]).to include("1")
        expect(tag_data["partners_count"]).to include("text-emerald-600")
      end

      it "renders updated_at as relative time" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["updated_at"]).to include("Today")
      end

      it "renders actions with edit button" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["actions"]).to include("Edit")
        expect(tag_data["actions"]).to include("href=")
      end
    end
  end
end
