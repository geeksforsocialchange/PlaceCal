# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Import runs" do
  let(:calendar) { create(:calendar, importer_mode: "ical", strategy: "no_location").tap { it.update!(calendar_state: "in_queue") } }
  let(:start) { 2.days.from_now.utc.strftime("%Y%m%dT%H%M%SZ") }
  let(:finish) { (2.days.from_now + 1.hour).utc.strftime("%Y%m%dT%H%M%SZ") }

  def feed(*events)
    "BEGIN:VCALENDAR\nVERSION:2.0\n#{events.join("\n")}\nEND:VCALENDAR\n"
  end

  def vevent(uid, summary, dtstart: start, dtend: finish, extra: nil)
    ["BEGIN:VEVENT", "UID:#{uid}", "DTSTART:#{dtstart}", "DTEND:#{dtend}", "SUMMARY:#{summary}", extra, "END:VEVENT"].compact.join("\n")
  end

  def import(force: true)
    calendar.update_columns(calendar_state: "in_queue") # rubocop:disable Rails/SkipsModelValidations
    CalendarImporterJob.perform_now(calendar.id, Time.zone.today, force)
    calendar.import_runs.latest_first.first
  end

  context "when a feed is read" do
    before do
      stub_request(:get, calendar.source).to_return(status: 200, body: feed(
        vevent("one@example.com", "Coffee morning"),
        vevent("private@example.com", "Someone's birthday", extra: "CLASS:PRIVATE"),
        vevent("old@example.com", "Last year's fair", dtstart: "20200101T100000Z", dtend: "20200101T110000Z")
      ))
    end

    it "records the outcome, the counts and how each source event fared" do
      run = import

      expect(run).to have_attributes(outcome: "imported", importer: "ical", events_added: 1, events_changed: 0, events_skipped: 2)
      expect(run.finished_at).to be_present
      expect(run.events.pluck(:uid, :title, :location_result, :reason, :occurrences)).to contain_exactly(
        ["one@example.com", "Coffee morning", "none", nil, 1],
        ["private@example.com", nil, "skipped", "private", 0],
        ["old@example.com", "Last year's fair", "skipped", "no_dates", 0]
      )
    end

    it "keeps the last import's results and notices through an unchanged check" do
      first = import
      calendar.update_columns(notices: ["Something to look at"]) # rubocop:disable Rails/SkipsModelValidations

      second = import(force: false)

      expect(second).to have_attributes(outcome: "unchanged", events_added: 0)
      expect(second.events).to be_empty
      expect(first.events.count).to eq(3)
      expect(calendar.reload.notices).to eq(["Something to look at"])
    end

    it "keeps event rows only for the latest import" do
      first = import
      second = import

      expect(first.events).to be_empty
      expect(second.events.count).to eq(3)
    end
  end

  it "records a source that can't be reached as a bad source, with its message" do
    stub_request(:get, calendar.source).to_return(status: 404)

    run = import

    expect(run.outcome).to eq("bad_source")
    expect(run.error).to eq(calendar.reload.critical_error)
  end

  it "records an unexpected error" do
    stub_request(:get, calendar.source).to_return(status: 200, body: feed(vevent("one@example.com", "Coffee morning")))
    allow_any_instance_of(CalendarImporter::EventResolver).to receive(:save_all_occurrences).and_raise("boom") # rubocop:disable RSpec/AnyInstance

    expect { import }.to raise_error(RuntimeError, "boom")
    run = calendar.import_runs.sole
    expect(run.outcome).to eq("error")
    expect(run.error).to include("boom")
  end
end
