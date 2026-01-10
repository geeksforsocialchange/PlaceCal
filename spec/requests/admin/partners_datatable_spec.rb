# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Partners Datatable JSON API", type: :request do
  let(:user) { create(:root_user) }

  before { sign_in user }

  # Helper to make datatable requests with proper parameters
  def datatable_request(params = {})
    base_params = {
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => {
        "0" => { "data" => "name", "name" => "name", "searchable" => "true", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "1" => { "data" => "ward", "name" => "ward", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "partnerships", "name" => "partnerships", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "calendars", "name" => "calendars", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "admins", "name" => "admins", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "categories", "name" => "categories", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "updated_at", "name" => "updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "7" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "6", "dir" => "desc" } }
    }

    get admin_partners_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/partners.json" do
    context "basic functionality" do
      let!(:partner1) { create(:partner, name: "Alpha Partner") }
      let!(:partner2) { create(:partner, name: "Beta Partner") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to be_successful
        expect(response.content_type).to include("application/json")

        json = response.parsed_body
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

      it "returns all partners in data array" do
        datatable_request

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(2)
        expect(json["recordsFiltered"]).to eq(2)
        expect(json["data"].length).to eq(2)
      end

      it "includes partner name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Alpha Partner")
        expect(names.join).to include("Beta Partner")
      end
    end

    context "record counts with filters" do
      let!(:partner_with_calendar) { create(:partner, name: "Unique Alpha") }
      let!(:partner_without_calendar) { create(:partner, name: "Unique Beta") }

      before { create(:calendar, partner: partner_with_calendar) }

      it "recordsTotal remains constant when filters applied" do
        datatable_request("filter" => { "calendar_status" => "connected" })

        json = response.parsed_body
        # Total should always show all partners
        expect(json["recordsTotal"]).to eq(2)
        # Filtered should show only matching partners
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "recordsTotal remains constant with search" do
        datatable_request("search" => { "value" => "Unique Alpha" })

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(2)
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "recordsTotal remains constant with multiple filters" do
        create(:partner_admin, partner: partner_with_calendar)

        datatable_request("filter" => {
                            "calendar_status" => "connected",
                            "has_admins" => "yes"
                          })

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(2)
        expect(json["recordsFiltered"]).to eq(1)
      end
    end

    context "search functionality" do
      let!(:matching_partner) { create(:partner, name: "Community Hub") }
      let!(:non_matching_partner) { create(:partner, name: "Sports Centre") }

      it "filters partners by search term" do
        datatable_request("search" => { "value" => "Community" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].length).to eq(1)
        expect(json["data"].first["name"]).to include("Community Hub")
      end

      it "returns empty results for non-matching search" do
        datatable_request("search" => { "value" => "nonexistent12345" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
        expect(json["data"]).to be_empty
      end

      it "search is case insensitive" do
        datatable_request("search" => { "value" => "COMMUNITY" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "partial matches work" do
        datatable_request("search" => { "value" => "Commun" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
      end
    end

    context "sorting" do
      let!(:partner_a) { create(:partner, name: "Alpha Partner", updated_at: 1.day.ago) }
      let!(:partner_z) { create(:partner, name: "Zeta Partner", updated_at: 1.hour.ago) }
      let!(:partner_m) { create(:partner, name: "Middle Partner", updated_at: 2.days.ago) }

      it "sorts by name ascending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "asc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.first).to include("Alpha Partner")
        expect(names.last).to include("Zeta Partner")
      end

      it "sorts by name descending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "desc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.first).to include("Zeta Partner")
        expect(names.last).to include("Alpha Partner")
      end

      it "sorts by updated_at descending (default)" do
        datatable_request("order" => { "0" => { "column" => "6", "dir" => "desc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        # Most recently updated first
        expect(names.first).to include("Zeta Partner")
      end

      it "sorts by updated_at ascending" do
        datatable_request("order" => { "0" => { "column" => "6", "dir" => "asc" } })

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        # Oldest first
        expect(names.first).to include("Middle Partner")
      end
    end

    context "pagination" do
      before do
        30.times { |i| create(:partner, name: "Partner #{i.to_s.rjust(2, '0')}") }
      end

      it "returns first page with 25 records by default" do
        datatable_request

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(30)
        expect(json["data"].length).to eq(25)
      end

      it "returns second page when start is 25" do
        datatable_request("start" => "25", "length" => "25")

        json = response.parsed_body
        expect(json["data"].length).to eq(5)
      end

      it "respects custom page length" do
        datatable_request("length" => "10")

        json = response.parsed_body
        expect(json["data"].length).to eq(10)
      end
    end

    context "calendar status filter" do
      let!(:partner_with_calendar) { create(:partner, name: "With Calendar") }
      let!(:partner_without_calendar) { create(:partner, name: "Without Calendar") }

      before do
        create(:calendar, partner: partner_with_calendar)
      end

      it "filters partners with connected calendars" do
        datatable_request("filter" => { "calendar_status" => "connected" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("With Calendar")
      end

      it "filters partners without calendars" do
        datatable_request("filter" => { "calendar_status" => "none" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Without Calendar")
      end
    end

    context "admin users filter" do
      let!(:partner_with_admin) { create(:partner, name: "With Admin") }
      let!(:partner_without_admin) { create(:partner, name: "Without Admin") }

      before do
        create(:partner_admin, partner: partner_with_admin)
      end

      it "filters partners with admin users" do
        datatable_request("filter" => { "has_admins" => "yes" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("With Admin")
      end

      it "filters partners without admin users" do
        datatable_request("filter" => { "has_admins" => "no" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Without Admin")
      end
    end

    context "partnership filter" do
      let!(:partnership1) { create(:partnership, name: "Partnership A") }
      let!(:partnership2) { create(:partnership, name: "Partnership B") }
      let!(:partner_in_partnership1) { create(:partner, name: "In Partnership A") }
      let!(:partner_in_partnership2) { create(:partner, name: "In Partnership B") }
      let!(:partner_no_partnership) { create(:partner, name: "No Partnership") }

      before do
        partner_in_partnership1.tags << partnership1
        partner_in_partnership2.tags << partnership2
      end

      it "filters by specific partnership" do
        datatable_request("filter" => { "partnership" => partnership1.id.to_s })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("In Partnership A")
      end

      it "returns no results for non-existent partnership" do
        datatable_request("filter" => { "partnership" => "999999" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
      end
    end

    context "category filter" do
      let!(:category1) { create(:category, name: "Health") }
      let!(:category2) { create(:category, name: "Sports") }
      let!(:partner_health) { create(:partner, name: "Health Partner") }
      let!(:partner_sports) { create(:partner, name: "Sports Partner") }
      let!(:partner_no_category) { create(:partner, name: "No Category") }

      before do
        partner_health.tags << category1
        partner_sports.tags << category2
      end

      it "filters by specific category" do
        datatable_request("filter" => { "category" => category1.id.to_s })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Health Partner")
      end
    end

    context "district filter" do
      let!(:district) { create(:neighbourhood, name: "Test District", unit: "district") }
      let!(:ward_in_district) { create(:neighbourhood, name: "Test Ward", unit: "ward", parent: district) }
      let!(:other_ward) { create(:neighbourhood, name: "Other Ward", unit: "ward") }

      let!(:partner_in_district) do
        address = create(:address, neighbourhood: ward_in_district)
        create(:partner, name: "In District", address: address)
      end

      let!(:partner_outside_district) do
        address = create(:address, neighbourhood: other_ward)
        create(:partner, name: "Outside District", address: address)
      end

      it "filters partners by district (includes all wards in district)" do
        datatable_request("filter" => { "district" => district.id.to_s })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("In District")
      end
    end

    context "ward filter" do
      let!(:ward1) { create(:neighbourhood, name: "Ward One", unit: "ward") }
      let!(:ward2) { create(:neighbourhood, name: "Ward Two", unit: "ward") }

      let!(:partner_ward1) do
        address = create(:address, neighbourhood: ward1)
        create(:partner, name: "In Ward One", address: address)
      end

      let!(:partner_ward2) do
        address = create(:address, neighbourhood: ward2)
        create(:partner, name: "In Ward Two", address: address)
      end

      it "filters partners by specific ward" do
        datatable_request("filter" => { "ward" => ward1.id.to_s })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("In Ward One")
      end
    end

    context "multiple filters combined" do
      let!(:partnership) { create(:partnership, name: "Test Partnership") }
      let!(:category) { create(:category, name: "Test Category") }

      let!(:partner_both) { create(:partner, name: "Both Filters") }
      let!(:partner_partnership_only) { create(:partner, name: "Partnership Only") }
      let!(:partner_category_only) { create(:partner, name: "Category Only") }
      let!(:partner_neither) { create(:partner, name: "Neither") }

      before do
        create(:calendar, partner: partner_both)
        create(:calendar, partner: partner_partnership_only)
        partner_both.tags << partnership
        partner_both.tags << category
        partner_partnership_only.tags << partnership
        partner_category_only.tags << category
      end

      it "combines calendar and partnership filters" do
        datatable_request("filter" => {
                            "calendar_status" => "connected",
                            "partnership" => partnership.id.to_s
                          })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(2)
        names = json["data"].map { |d| d["name"] }.join
        expect(names).to include("Both Filters")
        expect(names).to include("Partnership Only")
      end

      it "combines multiple filters for precise matching" do
        datatable_request("filter" => {
                            "calendar_status" => "connected",
                            "partnership" => partnership.id.to_s,
                            "category" => category.id.to_s
                          })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Both Filters")
      end

      it "returns empty when filters have no intersection" do
        datatable_request("filter" => {
                            "calendar_status" => "none",
                            "partnership" => partnership.id.to_s
                          })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
      end
    end

    context "search combined with filters" do
      let!(:partnership) { create(:partnership) }
      let!(:matching_partner) { create(:partner, name: "Community Center") }
      let!(:filtered_partner) { create(:partner, name: "Sports Center") }

      before do
        matching_partner.tags << partnership
        filtered_partner.tags << partnership
      end

      it "applies both search and filter" do
        datatable_request(
          "search" => { "value" => "Community" },
          "filter" => { "partnership" => partnership.id.to_s }
        )

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Community Center")
      end
    end

    context "edge cases" do
      it "handles empty database gracefully" do
        datatable_request

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(0)
        expect(json["recordsFiltered"]).to eq(0)
        expect(json["data"]).to be_empty
      end

      it "handles special characters in search" do
        create(:partner, name: "Partner & Associates")
        datatable_request("search" => { "value" => "&" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "handles very long search terms" do
        datatable_request("search" => { "value" => "a" * 500 })

        expect(response).to be_successful
        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
      end

      it "handles invalid filter values gracefully" do
        create(:partner)
        datatable_request("filter" => { "partnership" => "invalid" })

        expect(response).to be_successful
        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
      end
    end

    context "data rendering" do
      let!(:ward) { create(:neighbourhood, name: "Test Ward", unit: "ward") }
      let!(:partnership) { create(:partnership, name: "Test Partnership") }
      let!(:category) { create(:category, name: "Test Category") }
      let!(:partner) do
        address = create(:address, neighbourhood: ward)
        create(:partner, name: "Full Partner", address: address)
      end

      before do
        create(:calendar, partner: partner)
        create(:partner_admin, partner: partner)
        partner.tags << partnership
        partner.tags << category
      end

      it "renders partner name cell with link" do
        datatable_request

        json = response.parsed_body
        name_cell = json["data"].first["name"]
        expect(name_cell).to include("Full Partner")
        expect(name_cell).to include("href=")
      end

      it "renders partner ID and slug in name cell" do
        datatable_request

        json = response.parsed_body
        name_cell = json["data"].first["name"]
        expect(name_cell).to include("fa-hashtag")
        expect(name_cell).to include(partner.id.to_s)
        expect(name_cell).to include("fa-link")
        expect(name_cell).to include(partner.slug)
      end

      it "renders ward cell" do
        datatable_request

        json = response.parsed_body
        ward_cell = json["data"].first["ward"]
        expect(ward_cell).to include("Test Ward")
      end

      it "renders partnerships as clickable filters" do
        datatable_request

        json = response.parsed_body
        partnerships_cell = json["data"].first["partnerships"]
        expect(partnerships_cell).to include("Test Partnership")
        expect(partnerships_cell).to include("data-filter-column")
      end

      it "renders calendar status indicator" do
        datatable_request

        json = response.parsed_body
        calendars_cell = json["data"].first["calendars"]
        # Should show check icon for connected calendar
        expect(calendars_cell).to include("svg")
      end

      it "renders admin status indicator" do
        datatable_request

        json = response.parsed_body
        admins_cell = json["data"].first["admins"]
        expect(admins_cell).to include("svg")
      end

      it "renders updated_at as relative time" do
        datatable_request

        json = response.parsed_body
        updated_cell = json["data"].first["updated_at"]
        expect(updated_cell).to include("Today").or include("Yesterday").or include("ago")
      end

      it "renders actions with edit button" do
        datatable_request

        json = response.parsed_body
        actions_cell = json["data"].first["actions"]
        expect(actions_cell).to include("Edit")
        expect(actions_cell).to include("href=")
      end
    end
  end
end
