# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe "Admin::Calendars Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable
  let(:datatable_columns) do
    [
      { data: :name, searchable: true, orderable: true },
      { data: :partner },
      { data: :state },
      { data: :events },
      { data: :notices, orderable: true },
      { data: :last_import_at, orderable: true },
      { data: :checksum_updated_at, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 5)
    get admin_calendars_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/calendars.json" do
    context "basic functionality" do
      let!(:calendar) { create(:calendar, name: "Test Calendar") }

      it_behaves_like "datatable JSON structure"

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

      it_behaves_like "datatable search",
                      search_field: :name,
                      matching_value: "Community",
                      non_matching_value: "Sports"
    end

    context "sorting" do
      let!(:calendar_a) { create(:calendar, name: "Alpha Calendar") }
      let!(:calendar_z) { create(:calendar, name: "Zeta Calendar") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :name,
                      first_value: "Alpha",
                      last_value: "Zeta"
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
        idle_calendar.update_column(:calendar_state, "idle")
        error_calendar.update_column(:calendar_state, "error")
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

      before { create(:event, calendar: calendar_with_events) }

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_events",
                      field: :name,
                      yes_value: "With Events",
                      no_value: "Without Events"
    end

    context "has_notices filter" do
      let!(:calendar_with_notices) { create(:calendar, name: "With Notices", notice_count: 5) }
      let!(:calendar_without_notices) { create(:calendar, name: "Without Notices", notice_count: 0) }

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_notices",
                      field: :name,
                      yes_value: "With Notices",
                      no_value: "Without Notices"
    end

    context "multiple filters combined" do
      let!(:partner) { create(:partner, name: "Test Partner") }
      let!(:matching_calendar) { create(:calendar, name: "Match Calendar", partner: partner) }
      let!(:other_calendar) { create(:calendar, name: "Other Calendar") }

      before { create(:event, calendar: matching_calendar) }

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
        expect(name_html).to include("##{calendar.id}")
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

      it_behaves_like "datatable renders relative time", field: :last_import_at
      it_behaves_like "datatable renders edit button"
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
