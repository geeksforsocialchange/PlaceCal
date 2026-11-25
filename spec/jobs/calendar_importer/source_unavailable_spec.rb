# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "when Eventbrite keeps failing" do
  let(:url) { "https://www.eventbrite.co.uk/o/test-organiser-12345678" }
  let!(:calendar) do
    create(:calendar, source: url, importer_mode: "eventbrite", strategy: "no_location")
      .tap { |cal| cal.update_columns(last_checksum: "previous-checksum", last_import_at: 2.days.ago) } # rubocop:disable Rails/SkipsModelValidations
  end
  let!(:upcoming_event) do
    create(:event, calendar:, organiser: calendar.organiser, dtstart: 1.month.from_now, dtend: 1.month.from_now + 2.hours)
  end

  let(:api) { "https://www.eventbriteapi.com/v3/organizers/12345678" }

  def events_page(page, events: [], page_count: 1)
    { status: 200, body: { pagination: { page_number: page, page_count: }, events: }.to_json }
  end

  before do
    allow(CalendarImporter::Parsers::Base).to receive(:sleep)
    stub_request(:get, url).to_return(status: 200, body: "<html></html>")
    stub_request(:get, "#{api}/").to_return(status: 500, body: "{}")
  end

  def import
    calendar.update!(calendar_state: "in_worker")
    described_class.new(calendar, Time.zone.today, false).run
    calendar.reload
  end

  it "skips the import, leaving the events, checksum and empty-feed record alone, and says why", :aggregate_failures do
    import

    expect(calendar.calendar_state).to eq("idle")
    expect(calendar.notices).to eq(["Eventbrite didn't respond, so this import was skipped and the calendar's events were left as they were."])
    expect(calendar.last_checksum).to eq("previous-checksum")
    expect(calendar.last_import_at).to be_within(1.minute).of(2.days.ago)
    expect(calendar.feed_empty_since).to be_nil
    expect(Event.exists?(upcoming_event.id)).to be(true)
  end

  it "skips the whole import when a later page fails, rather than importing a partial list" do
    stub_request(:get, "#{api}/").to_return(status: 200, body: "{}")
    stub_request(:get, "#{api}/events/?expand=venue&page=1").to_return(events_page(1, page_count: 2))
    stub_request(:get, "#{api}/events/?expand=venue&page=2").to_return(status: 503, body: "")
    import

    expect(calendar.notices.sole).to include("Eventbrite didn't respond")
    expect(Event.exists?(upcoming_event.id)).to be(true)
    expect(calendar.feed_empty_since).to be_nil
  end

  it "still treats an organiser with no events as an empty feed" do
    stub_request(:get, "#{api}/").to_return(status: 200, body: "{}")
    stub_request(:get, "#{api}/events/?expand=venue&page=1").to_return(events_page(1))
    import

    expect(calendar.feed_empty_since).to be_present
  end

  it "removes no events when every hourly import fails for more than 48 hours" do
    import
    Timecop.freeze(49.hours.from_now)
    import

    expect(Event.exists?(upcoming_event.id)).to be(true)
  end
end
