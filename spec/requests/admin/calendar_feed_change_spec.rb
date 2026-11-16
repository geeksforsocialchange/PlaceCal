# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin calendar update when the feed changes", type: :request do
  let(:user) { create(:root_user) }
  let!(:calendar) do
    create(:calendar, importer_mode: "ical", source: "https://example.com/old.ics").tap do |cal|
      cal.update_columns(calendar_state: "error", critical_error: "Feed returned 404", last_checksum: "abc123") # rubocop:disable Rails/SkipsModelValidations
    end
  end
  let(:form_params) do
    { name: calendar.name, source: calendar.source, importer_mode: calendar.importer_mode,
      api_token: "", organiser_id: calendar.organiser_id, strategy: calendar.strategy }
  end

  before do
    allow_any_instance_of(Calendar).to receive(:check_source_reachable)
    sign_in user
  end

  def update_calendar(**changes)
    put admin_calendar_url(calendar, host: admin_host), params: { calendar: form_params.merge(changes) }
    calendar.reload
  end

  it "queues a forced import of the new source and shows the calendar as importing", :aggregate_failures do
    expect { update_calendar(source: "https://example.com/new.ics") }
      .to have_enqueued_job(CalendarImporterJob).with(calendar.id, anything, true)

    expect(calendar.calendar_state).to eq("in_queue")
    expect([calendar.critical_error, calendar.last_checksum]).to eq([nil, nil])
    expect(flash[:success]).to eq(I18n.t("admin.calendars.flash.updated_and_queued"))

    follow_redirect!
    expect(response.body).to include(I18n.t("admin.calendars.importer.importing"))
  end

  it "queues an import when the calendar type changes" do
    expect { update_calendar(importer_mode: "ld-json") }.to have_enqueued_job(CalendarImporterJob)
  end

  it "queues an import when only the API key changes" do
    expect { update_calendar(api_token: "new-key") }.to have_enqueued_job(CalendarImporterJob)
  end

  it "does not queue an import when the feed is unchanged", :aggregate_failures do
    expect { update_calendar(name: "Renamed calendar") }.not_to have_enqueued_job(CalendarImporterJob)

    expect(calendar.calendar_state).to eq("error")
    expect(calendar.last_checksum).to eq("abc123")
    expect(flash[:success]).to eq(I18n.t("admin.calendars.flash.updated"))
  end

  it "treats a stored blank API key and a source with stray spaces as unchanged" do
    calendar.update_columns(api_token: "") # rubocop:disable Rails/SkipsModelValidations

    expect { update_calendar(name: "Renamed calendar", source: " #{calendar.source} ") }
      .not_to have_enqueued_job(CalendarImporterJob)
  end

  it "leaves a running import alone but clears the checksum so the next scan reads the new source", :aggregate_failures do
    calendar.update_columns(calendar_state: "in_worker") # rubocop:disable Rails/SkipsModelValidations

    expect { update_calendar(source: "https://example.com/new.ics") }.not_to have_enqueued_job(CalendarImporterJob)
    expect(calendar.last_checksum).to be_nil
    expect(flash[:success]).to eq(I18n.t("admin.calendars.flash.updated"))
  end
end
