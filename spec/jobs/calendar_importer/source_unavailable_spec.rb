# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "when Eventbrite keeps failing" do
  let(:url) { "https://www.eventbrite.co.uk/o/test-organiser-12345678" }
  let!(:calendar) do
    create(:calendar, source: url, importer_mode: "eventbrite", strategy: "no_location")
      .tap { |cal| cal.update_columns(last_checksum: "previous-checksum") } # rubocop:disable Rails/SkipsModelValidations
  end
  let!(:upcoming_event) do
    create(:event, calendar:, organiser: calendar.organiser, dtstart: 1.month.from_now, dtend: 1.month.from_now + 2.hours)
  end

  before do
    allow(CalendarImporter::Parsers::Base).to receive(:sleep)
    stub_request(:get, url).to_return(status: 200, body: "<html></html>")
    allow(EventbriteSDK::Organizer).to receive(:retrieve).and_raise(EventbriteSDK::InternalServerError.new("internal server error"))
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
    expect(calendar.feed_empty_since).to be_nil
    expect(Event.exists?(upcoming_event.id)).to be(true)
  end

  it "removes no events when every hourly import fails for more than 48 hours" do
    import
    Timecop.freeze(49.hours.from_now)
    import

    expect(Event.exists?(upcoming_event.id)).to be(true)
  end
end
