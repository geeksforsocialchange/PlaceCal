# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe CalendarDatatable do
  # Create a view context with access to URL helpers using a real controller
  let(:view_context) do
    controller = Admin::CalendarsController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end
  let(:calendars) { Calendar.all }

  # Helper to create datatable with params
  def create_datatable(params = {})
    default_params = ActionController::Parameters.new({
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => {
        "0" => { "data" => "name", "name" => "name", "searchable" => "true", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "1" => { "data" => "partner", "name" => "partner", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "state", "name" => "state", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "importer", "name" => "importer", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "events", "name" => "events", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "notices", "name" => "notices", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "last_import_at", "name" => "last_import_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "7" => { "data" => "checksum_updated_at", "name" => "checksum_updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "8" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "0", "dir" => "asc" } }
    }.deep_merge(params))

    described_class.new(default_params, view_context: view_context, calendars: calendars)
  end

  describe "#view_columns" do
    it "defines all required columns" do
      datatable = create_datatable

      columns = datatable.view_columns
      expect(columns.keys).to contain_exactly(
        :name, :partner, :state, :importer, :events, :notices, :last_import_at, :checksum_updated_at, :actions
      )
    end

    it "makes name column searchable" do
      datatable = create_datatable

      expect(datatable.view_columns[:name][:searchable]).to be true
    end

    it "makes partner column not orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:partner][:orderable]).to be false
    end

    it "makes state column not orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:state][:orderable]).to be false
    end

    it "makes notices column orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:notices][:orderable]).to be true
    end

    it "makes last_import_at column orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:last_import_at][:orderable]).to be true
    end
  end

  describe "#data" do
    let!(:partner) { create(:partner, name: "Test Partner") }
    let!(:calendar) { create(:calendar, name: "Test Calendar", partner: partner, notice_count: 5) }

    before do
      # Set to idle state for consistent testing (after_create sets to in_queue)
      calendar.update_column(:calendar_state, "idle")
    end

    it "returns array of hashes with all column keys" do
      datatable = create_datatable

      data = datatable.data
      expect(data).to be_an(Array)
      expect(data.first.keys).to contain_exactly(
        :name, :partner, :state, :importer, :events, :notices, :last_import_at, :checksum_updated_at, :actions
      )
    end

    context "name cell rendering" do
      it "includes calendar name" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("Test Calendar")
      end

      it "includes link to edit page" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("href=")
        expect(name_html).to include("/calendars/")
        expect(name_html).to include("/edit")
      end

      it "includes calendar ID" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("##{calendar.id}")
      end
    end

    context "partner cell rendering" do
      it "includes partner name" do
        datatable = create_datatable

        partner_html = datatable.data.first[:partner]
        expect(partner_html).to include("Test Partner")
      end

      it "includes filter data attributes" do
        datatable = create_datatable

        partner_html = datatable.data.first[:partner]
        expect(partner_html).to include("data-filter-column=\"partner\"")
        expect(partner_html).to include("data-filter-value=\"#{partner.id}\"")
      end
    end

    context "state cell rendering" do
      it "shows green check for idle state" do
        datatable = create_datatable

        state_html = datatable.data.first[:state]
        expect(state_html).to include("text-emerald-600")
        expect(state_html).to include("Idle")
      end

      it "shows orange spinner for in_queue state" do
        calendar.update_column(:calendar_state, "in_queue")
        datatable = create_datatable

        state_html = datatable.data.first[:state]
        expect(state_html).to include("text-orange-500")
        expect(state_html).to include("Queued")
      end

      it "shows red icon for error state" do
        calendar.update_column(:calendar_state, "error")
        datatable = create_datatable

        state_html = datatable.data.first[:state]
        expect(state_html).to include("text-red-600")
        expect(state_html).to include("error")
      end
    end

    context "notices cell rendering" do
      it "shows notice count when notices exist" do
        datatable = create_datatable

        notices_html = datatable.data.first[:notices]
        expect(notices_html).to include("5")
        expect(notices_html).to include("text-amber-700")
      end

      it "shows green check when no notices" do
        calendar.update_column(:notice_count, 0)
        datatable = create_datatable

        notices_html = datatable.data.first[:notices]
        expect(notices_html).to include("text-emerald-600")
      end
    end

    context "events cell rendering" do
      it "shows check for calendar with events" do
        create(:event, calendar: calendar)
        datatable = create_datatable

        events_html = datatable.data.first[:events]
        expect(events_html).to include("text-emerald-600")
      end

      it "shows cross for calendar without events" do
        datatable = create_datatable

        events_html = datatable.data.first[:events]
        expect(events_html).to include("text-gray-500")
      end
    end

    context "actions cell rendering" do
      it "includes edit button" do
        datatable = create_datatable

        actions_html = datatable.data.first[:actions]
        expect(actions_html).to include("Edit")
        expect(actions_html).to include("href=")
      end
    end
  end

  describe "#get_raw_records with filters" do
    let!(:partner1) { create(:partner, name: "Partner 1") }
    let!(:partner2) { create(:partner, name: "Partner 2") }
    let!(:calendar1) { create(:calendar, name: "Calendar 1", partner: partner1, notice_count: 3) }
    let!(:calendar2) { create(:calendar, name: "Calendar 2", partner: partner2, notice_count: 0) }

    before do
      calendar1.update_column(:calendar_state, "idle")
      calendar2.update_column(:calendar_state, "error")
    end

    context "state filter" do
      it "filters by idle state" do
        datatable = create_datatable("filter" => { "state" => "idle" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 1")
        expect(records.pluck(:name)).not_to include("Calendar 2")
      end

      it "filters by error state" do
        datatable = create_datatable("filter" => { "state" => "error" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 2")
        expect(records.pluck(:name)).not_to include("Calendar 1")
      end
    end

    context "partner filter" do
      it "filters by specific partner" do
        datatable = create_datatable("filter" => { "partner" => partner1.id.to_s })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 1")
        expect(records.pluck(:name)).not_to include("Calendar 2")
      end
    end

    context "has_events filter" do
      before { create(:event, calendar: calendar1, summary: "Unique Event For Filters Test") }

      it "filters calendars with events" do
        datatable = create_datatable("filter" => { "has_events" => "yes" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 1")
        expect(records.pluck(:name)).not_to include("Calendar 2")
      end

      it "filters calendars without events" do
        datatable = create_datatable("filter" => { "has_events" => "no" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 2")
        expect(records.pluck(:name)).not_to include("Calendar 1")
      end
    end

    context "has_notices filter" do
      it "filters calendars with notices" do
        datatable = create_datatable("filter" => { "has_notices" => "yes" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 1")
        expect(records.pluck(:name)).not_to include("Calendar 2")
      end

      it "filters calendars without notices" do
        datatable = create_datatable("filter" => { "has_notices" => "no" })

        records = datatable.send(:get_raw_records)
        expect(records.pluck(:name)).to include("Calendar 2")
        expect(records.pluck(:name)).not_to include("Calendar 1")
      end
    end
  end

  describe "#records_total_count" do
    let!(:calendar1) { create(:calendar, name: "Calendar 1") }
    let!(:calendar2) { create(:calendar, name: "Calendar 2") }

    it "returns total count regardless of filters" do
      datatable = create_datatable("filter" => { "state" => "idle" })

      expect(datatable.records_total_count).to eq(2)
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
