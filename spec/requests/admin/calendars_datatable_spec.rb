# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe "Admin::Calendars Datatable JSON API", type: :request do
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
        "1" => { "data" => "partner", "name" => "partner", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "state", "name" => "state", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "events", "name" => "events", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "notices", "name" => "notices", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "last_import_at", "name" => "last_import_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "checksum_updated_at", "name" => "checksum_updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "7" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "5", "dir" => "desc" } }
    }
    get admin_calendars_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/calendars.json" do
    context "basic functionality" do
      let!(:calendar) { create(:calendar, name: "Test Calendar") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("draw")
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

      it "returns all calendars in data array" do
        create(:calendar, name: "Another Calendar")

        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(2)
      end

      it "includes calendar name in response data" do
        datatable_request

        json = response.parsed_body
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Test Calendar")
      end
    end

    context "record counts with filters" do
      let!(:calendar_idle) { create(:calendar, name: "Idle Calendar") }
      let!(:calendar_error) { create(:calendar, name: "Error Calendar") }

      before do
        # after_create callback sets state to in_queue, so we need to reset it
        calendar_idle.update_column(:calendar_state, "idle")
        calendar_error.update_column(:calendar_state, "error")
      end

      it "recordsTotal remains constant when filters applied" do
        datatable_request("filter" => { "state" => "idle" })

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(2)
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "recordsTotal remains constant with search" do
        datatable_request("search" => { "value" => "Idle" })

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(2)
        expect(json["recordsFiltered"]).to eq(1)
      end
    end

    context "search functionality" do
      let!(:matching_calendar) { create(:calendar, name: "Community Events") }
      let!(:non_matching_calendar) { create(:calendar, name: "Sports Schedule") }

      it "filters calendars by search term" do
        datatable_request("search" => { "value" => "Community" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        names = json["data"].map { |d| d["name"] }
        expect(names.join).to include("Community Events")
      end

      it "search is case insensitive" do
        datatable_request("search" => { "value" => "COMMUNITY" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
      end

      it "returns empty results for non-matching search" do
        datatable_request("search" => { "value" => "nonexistent12345" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(0)
        expect(json["data"]).to be_empty
      end
    end

    context "sorting" do
      let!(:calendar_a) { create(:calendar, name: "Alpha Calendar") }
      let!(:calendar_z) { create(:calendar, name: "Zeta Calendar") }

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

    context "pagination" do
      before { 30.times { |i| create(:calendar, name: "Calendar #{i.to_s.rjust(2, '0')}") } }

      it "returns first page with 25 records by default" do
        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(25)
      end

      it "returns second page when start is 25" do
        datatable_request("start" => "25")

        json = response.parsed_body
        expect(json["data"].length).to eq(5)
      end

      it "respects custom page length" do
        datatable_request("length" => "10")

        json = response.parsed_body
        expect(json["data"].length).to eq(10)
      end
    end

    context "state filter" do
      let!(:idle_calendar) { create(:calendar, name: "Idle Calendar") }
      let!(:error_calendar) { create(:calendar, name: "Error Calendar") }
      let!(:queued_calendar) { create(:calendar, name: "Queued Calendar") }

      before do
        # after_create callback sets state to in_queue, so we need to set states explicitly
        idle_calendar.update_column(:calendar_state, "idle")
        error_calendar.update_column(:calendar_state, "error")
        # queued_calendar is already in_queue from the callback
      end

      it "filters by idle state" do
        datatable_request("filter" => { "state" => "idle" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Idle")
      end

      it "filters by error state" do
        datatable_request("filter" => { "state" => "error" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Error")
      end

      it "filters by in_queue state" do
        datatable_request("filter" => { "state" => "in_queue" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Queued")
      end
    end

    context "partner filter" do
      let!(:partner_a) { create(:partner, name: "Partner Alpha") }
      let!(:partner_b) { create(:partner, name: "Partner Beta") }
      let!(:calendar_a) { create(:calendar, name: "Calendar A", partner: partner_a) }
      let!(:calendar_b) { create(:calendar, name: "Calendar B", partner: partner_b) }

      it "filters by specific partner" do
        datatable_request("filter" => { "partner" => partner_a.id.to_s })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Calendar A")
      end
    end

    context "has_events filter" do
      let!(:calendar_with_events) { create(:calendar, name: "With Events") }
      let!(:calendar_without_events) { create(:calendar, name: "Without Events") }

      before do
        create(:event, calendar: calendar_with_events)
      end

      it "filters calendars with events" do
        datatable_request("filter" => { "has_events" => "yes" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("With Events")
      end

      it "filters calendars without events" do
        datatable_request("filter" => { "has_events" => "no" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Without Events")
      end
    end

    context "has_notices filter" do
      let!(:calendar_with_notices) { create(:calendar, name: "With Notices", notice_count: 5) }
      let!(:calendar_without_notices) { create(:calendar, name: "Without Notices", notice_count: 0) }

      it "filters calendars with notices" do
        datatable_request("filter" => { "has_notices" => "yes" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("With Notices")
      end

      it "filters calendars without notices" do
        datatable_request("filter" => { "has_notices" => "no" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Without Notices")
      end
    end

    context "multiple filters combined" do
      let!(:partner) { create(:partner, name: "Test Partner") }
      let!(:matching_calendar) { create(:calendar, name: "Match Calendar", partner: partner) }
      let!(:other_calendar) { create(:calendar, name: "Other Calendar") }

      before do
        create(:event, calendar: matching_calendar)
      end

      it "combines partner and has_events filters" do
        datatable_request("filter" => {
                            "partner" => partner.id.to_s,
                            "has_events" => "yes"
                          })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Match")
      end
    end

    context "search combined with filters" do
      let!(:partner) { create(:partner, name: "Partner") }
      let!(:matching_calendar) { create(:calendar, name: "Alpha Calendar", partner: partner) }
      let!(:other_calendar) { create(:calendar, name: "Beta Calendar", partner: partner) }

      it "applies both search and filter" do
        datatable_request(
          "search" => { "value" => "Alpha" },
          "filter" => { "partner" => partner.id.to_s }
        )

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
        expect(json["data"].first["name"]).to include("Alpha")
      end
    end

    context "edge cases" do
      it "handles empty database gracefully" do
        datatable_request

        json = response.parsed_body
        expect(json["recordsTotal"]).to eq(0)
        expect(json["data"]).to be_empty
      end

      it "handles special characters in search" do
        create(:calendar, name: "Test & Calendar <script>")

        datatable_request("search" => { "value" => "Test &" })

        json = response.parsed_body
        expect(json["recordsFiltered"]).to eq(1)
      end
    end

    context "data rendering" do
      let!(:partner) { create(:partner, name: "Render Partner") }
      let!(:calendar) { create(:calendar, name: "Render Test", partner: partner, notice_count: 3) }

      before do
        # Set state to idle for state icon test (after_create callback sets it to in_queue)
        calendar.update_column(:calendar_state, "idle")
        calendar.update_column(:last_import_at, Time.current)
        create(:event, calendar: calendar)
      end

      it "renders calendar name cell with link" do
        datatable_request

        json = response.parsed_body
        name_html = json["data"].first["name"]
        expect(name_html).to include("Render Test")
        expect(name_html).to include("href=")
        expect(name_html).to include("ID:")
      end

      it "renders partner cell as clickable filter" do
        datatable_request

        json = response.parsed_body
        partner_html = json["data"].first["partner"]
        expect(partner_html).to include("Render Partner")
        expect(partner_html).to include("data-filter-column=\"partner\"")
      end

      it "renders state cell with icon" do
        datatable_request

        json = response.parsed_body
        state_html = json["data"].first["state"]
        expect(state_html).to include("svg")
        expect(state_html).to include("text-emerald-600")
      end

      it "renders events cell" do
        datatable_request

        json = response.parsed_body
        events_html = json["data"].first["events"]
        expect(events_html).to include("svg")
      end

      it "renders notices cell with count" do
        datatable_request

        json = response.parsed_body
        notices_html = json["data"].first["notices"]
        expect(notices_html).to include("3")
        expect(notices_html).to include("text-amber-600")
      end

      it "renders last_import_at as relative time" do
        datatable_request

        json = response.parsed_body
        time_html = json["data"].first["last_import_at"]
        expect(time_html).to include("Today")
      end

      it "renders actions with edit button" do
        datatable_request

        json = response.parsed_body
        actions_html = json["data"].first["actions"]
        expect(actions_html).to include("Edit")
        expect(actions_html).to include("href=")
      end
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
