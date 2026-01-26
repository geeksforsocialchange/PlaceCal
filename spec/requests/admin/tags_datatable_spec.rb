# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tags Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable
  let(:datatable_columns) do
    [
      { data: :name, searchable: true, orderable: true },
      { data: :type, orderable: true },
      { data: :partners_count },
      { data: :updated_at, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 3)
    get admin_tags_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/tags.json" do
    context "basic functionality" do
      let!(:tag) { create(:tag, name: "Test Tag") }

      it_behaves_like "datatable JSON structure"

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

      it_behaves_like "datatable search",
                      search_field: :name,
                      matching_value: "Environment",
                      non_matching_value: "Sports"
    end

    context "sorting" do
      let!(:tag_a) { create(:tag, name: "Alpha Tag") }
      let!(:tag_z) { create(:tag, name: "Zeta Tag") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :name,
                      first_value: "Alpha",
                      last_value: "Zeta"
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

    context "has_partners filter" do
      let!(:partner) { create(:partner) }
      let!(:tag_with_partners) do
        tag = create(:tag, name: "Tag With Partners")
        tag.partners << partner
        tag
      end
      let!(:tag_without_partners) { create(:tag, name: "Tag Without Partners") }

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_partners",
                      field: :name,
                      yes_value: "With Partners",
                      no_value: "Without Partners"
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

      it "renders partners count cell" do
        datatable_request

        json = response.parsed_body
        tag_data = json["data"].find { |d| d["name"].include?("Render Test") }
        expect(tag_data["partners_count"]).to include("1")
        expect(tag_data["partners_count"]).to include("text-emerald-600")
      end

      it_behaves_like "datatable renders relative time", field: :updated_at
      it_behaves_like "datatable renders edit button"
    end
  end
end
