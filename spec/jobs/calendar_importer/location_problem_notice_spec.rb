# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::CalendarImporterTask, "with a calendar-wide location problem" do
  let(:url) { "https://calendar.example.org/rooms.ics" }
  let(:feed) do
    events = (1..3).map do |n|
      <<~VEVENT
        BEGIN:VEVENT
        UID:room-#{n}@example.org
        DTSTAMP:20221101T000000Z
        DTSTART:#{n.weeks.from_now.utc.strftime('%Y%m%dT100000Z')}
        DTEND:#{n.weeks.from_now.utc.strftime('%Y%m%dT120000Z')}
        SUMMARY:Session #{n}
        LOCATION:Room #{n}
        END:VEVENT
      VEVENT
    end
    "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//PlaceCal//Test//EN\n#{events.join}END:VCALENDAR\n".gsub("\n", "\r\n")
  end
  let!(:calendar) { create(:calendar, source: url, importer_mode: "ical", strategy: "event") }

  before do
    stub_request(:get, url).to_return(status: 200, body: feed, headers: { "Content-Type" => "text/calendar" })
    allow_any_instance_of(CalendarImporter::LocationResolver) # rubocop:disable RSpec/AnyInstance
      .to receive(:resolve).and_raise(CalendarImporter::LocationResolver::Problem, "Choose a default location.")
  end

  it "gives one notice however many events hit it" do
    calendar.update!(calendar_state: "in_worker")
    described_class.new(calendar, Time.zone.today, true).run

    expect(calendar.reload.notices).to eq(["Choose a default location."])
  end
end
