# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "notice order" do
  let(:url) { "https://calendar.example.org/order.ics" }
  let(:calendar) { create(:calendar, source: url, importer_mode: "ical", strategy: "event") }

  def vevent(uid, summary, start:, rrule: nil, location: nil)
    ["BEGIN:VEVENT", "UID:#{uid}", "DTSTART;TZID=Europe/London:#{start}", "DTEND;TZID=Europe/London:#{start.sub(/T\d{2}/, 'T23')}",
     ("RRULE:#{rrule}" if rrule), "SUMMARY:#{summary}", ("LOCATION:#{location}" if location), "END:VEVENT"].compact.join("\n")
  end

  before { Timecop.freeze(Time.zone.local(2026, 10, 29, 12)) }

  it "stores parser notices first, then event notices in feed order, then grouped ones" do
    stub_const("CalendarImporter::EventResolver::MAX_OCCURRENCES_PER_EVENT", 3)
    body = ["BEGIN:VCALENDAR", "VERSION:2.0",
            vevent("daily@example.com", "Daily", start: "20261104T190000", rrule: "FREQ=DAILY;COUNT=5"),
            vevent("blank@example.com", "", start: "20261105T190000"),
            "BEGIN:VEVENT\nUID:broken@example.com\nDTSTART:2026-11-0X\nSUMMARY:Broken\nEND:VEVENT",
            vevent("hall@example.com", "Choir", start: "20261106T190000", location: "Church Hall, 1 High Street"),
            "END:VCALENDAR", ""].join("\n")
    stub_request(:get, url).to_return(status: 200, body:)
    calendar.update!(calendar_state: "in_worker")

    described_class.new(calendar, Time.current, true).run

    expect(calendar.reload.notices).to eq([
                                            'Skipped "Broken" because its dates could not be read (Failed to parse "2026-11-0X" - invalid date).',
                                            '"Daily" repeats more than 3 times, so only its first 3 dates were imported.',
                                            "Summary can't be blank",
                                            'Couldn\'t read an address for "Choir" (Church Hall, 1 High Street): its location has no postcode.'
                                          ])
    expect(calendar.notice_count).to eq(4)
  end
end
