# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable (must match view_columns in user_datatable.rb)
  let(:datatable_columns) do
    [
      { data: :name, searchable: true, orderable: true },
      { data: :roles },
      { data: :last_sign_in_at, orderable: true },
      { data: :updated_at, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 3)
    get admin_users_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/users.json" do
    context "basic functionality" do
      let!(:user1) { create(:user, first_name: "Alice", last_name: "Johnson") }

      it_behaves_like "datatable JSON structure"

      it "returns all users in data array" do
        datatable_request

        json = response.parsed_body
        # admin_user + user1
        expect(json["data"].length).to eq(2)
      end

      it "includes user name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Alice Johnson")
      end
    end

    context "search functionality" do
      let!(:matching_user) { create(:user, first_name: "John", last_name: "Smith") }
      let!(:non_matching_user) { create(:user, first_name: "Jane", last_name: "Doe") }

      it_behaves_like "datatable search",
                      search_field: :name,
                      matching_value: "Smith",
                      non_matching_value: "Doe"
    end

    context "sorting" do
      let!(:user_a) { create(:user, last_name: "Adams") }
      let!(:user_z) { create(:user, last_name: "Zimmerman") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :name,
                      first_value: "Adams",
                      last_value: "Zimmerman"
    end

    context "pagination" do
      before { 30.times { |i| create(:user, last_name: "User#{i.to_s.rjust(2, '0')}") } }

      it "returns first page with 25 records by default" do
        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(25)
      end

      it "respects custom page length" do
        datatable_request("length" => "10")

        json = response.parsed_body
        expect(json["data"].length).to eq(10)
      end
    end

    context "role filter" do
      let!(:editor_user) { create(:user, first_name: "Editor", last_name: "UserEditor", role: :editor) }
      let!(:citizen_user) { create(:user, first_name: "Citizen", last_name: "UserCitizen", role: :citizen) }

      it "filters by root role" do
        datatable_request("filter" => { "role" => "root" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        # admin_user is the only root user
        expect(json["recordsFiltered"]).to eq(1)
        expect(names.join).not_to include("Citizen")
        expect(names.join).not_to include("Editor")
      end

      it "filters by citizen role" do
        datatable_request("filter" => { "role" => "citizen" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Citizen")
        expect(names.join).not_to include("Editor UserEditor")
      end
    end

    context "has_partners filter" do
      let!(:user_with_partner) { create(:partner_admin, first_name: "Partner", last_name: "Admin") }
      let!(:user_without_partner) { create(:user, first_name: "No", last_name: "Partners") }

      it "filters users with partners" do
        datatable_request("filter" => { "has_partners" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Partner Admin")
        expect(names.join).not_to include("No Partners")
      end

      it "filters users without partners" do
        datatable_request("filter" => { "has_partners" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("No Partners")
      end
    end

    context "has_neighbourhoods filter" do
      let!(:neighbourhood) { create(:neighbourhood) }
      let!(:user_with_neighbourhood) do
        user = create(:user, first_name: "Neighbourhood", last_name: "Admin")
        user.neighbourhoods << neighbourhood
        user
      end
      let!(:user_without_neighbourhood) { create(:user, first_name: "No", last_name: "Neighbourhoods") }

      it "filters users with neighbourhoods" do
        datatable_request("filter" => { "has_neighbourhoods" => "yes" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Neighbourhood Admin")
        expect(names.join).not_to include("No Neighbourhoods")
      end

      it "filters users without neighbourhoods" do
        datatable_request("filter" => { "has_neighbourhoods" => "no" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("No Neighbourhoods")
      end
    end

    context "data rendering" do
      let!(:partner) { create(:partner, name: "Test Partner") }
      let!(:neighbourhood) { create(:neighbourhood, name: "Test Neighbourhood") }
      let!(:user) do
        user = create(:user, first_name: "Test", last_name: "User", role: :editor)
        user.partners << partner
        user.neighbourhoods << neighbourhood
        user
      end

      it "renders user name cell with email subtitle" do
        datatable_request

        json = response.parsed_body
        user_data = json["data"].find { |d| d["name"].include?("Test User") }
        expect(user_data["name"]).to include("Test User")
        expect(user_data["name"]).to include(user.email)
        expect(user_data["name"]).to include("href=")
      end

      it "renders roles cell with badges" do
        datatable_request

        json = response.parsed_body
        user_data = json["data"].find { |d| d["name"].include?("Test User") }
        expect(user_data["roles"]).to include("Editor")
        expect(user_data["roles"]).to include("Partner Admin")
        expect(user_data["roles"]).to include("bg-blue-100")
        expect(user_data["roles"]).to include("bg-purple-100")
      end

      it_behaves_like "datatable renders relative time", field: :updated_at
      it_behaves_like "datatable renders edit button"
    end

    context "edge cases" do
      it "handles special characters in search" do
        create(:user, first_name: "Test", last_name: "OBrien")

        datatable_request("search" => { "value" => "OBrien" })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("OBrien")
      end
    end
  end
end
