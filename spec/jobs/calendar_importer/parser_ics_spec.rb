# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Ics do
  let(:blank_calendar) { Calendar.new }
  let(:parser) { described_class.new(blank_calendar) }

  describe "#parse_remote_calendars" do
    it "parses ICS" do
      ics_data = file_fixture("family-action-org-uk.ics").read
      events = parser.parse_remote_calendars(ics_data)

      expect(events.length).to eq(1)
    end

    it "keeps Outlook's repeating events at the same UK time across the clock change" do
      event = parser.parse_remote_calendars(file_fixture("outlook-gmt-standard-time.ics").read).first.events.first
      starts = event.occurrences_between(Time.utc(2026, 10, 20), Time.utc(2026, 11, 2)).map { |o| o.start_time.in_time_zone("Europe/London").strftime("%-d %b %H:%M") }

      expect(starts).to eq(["24 Oct 11:30", "31 Oct 11:30"])
    end

    it "keeps repeating events in other Outlook zones at the same local time across the clock change" do
      ics = file_fixture("outlook-gmt-standard-time.ics").read.gsub("GMT Standard Time", "W. Europe Standard Time")
      event = parser.parse_remote_calendars(ics).first.events.first
      starts = event.occurrences_between(Time.utc(2026, 10, 20), Time.utc(2026, 11, 2)).map { |o| o.start_time.in_time_zone("Europe/Berlin").strftime("%-d %b %H:%M") }

      expect(starts).to eq(["24 Oct 11:30", "31 Oct 11:30"])
    end

    it "handles missing ICAL data" do
      expect do
        parser.parse_remote_calendars("")
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, "Source returned empty ICS data")
    end

    it "handles badly formed ICAL data" do
      bad_ics_data = file_fixture("family-action-org-uk-bad.ics").read

      expect do
        parser.parse_remote_calendars(bad_ics_data)
      end.to raise_error(CalendarImporter::Exceptions::InvalidResponse, "Could not parse ICS response (Invalid iCalendar input line: */)")
    end
  end
end

RSpec.describe "ICS event parsing" do
  describe "bad ICS data handling" do
    it "catches and signals parsing bad ICS data" do
      bad_calendar_url = "https://calendar.google.com/calendar/u/0/r?tab=rc&pli=1"

      VCR.use_cassette("Importer ICS Bad Response", allow_playback_repeats: true) do
        calendar = create(:calendar, source: bad_calendar_url)
        args = {
          url: bad_calendar_url,
          from: Time.zone.today
        }

        parser = CalendarImporter::Parsers::Ics.new(calendar, args)

        expect do
          parser.calendar_to_events
        end.to raise_error(CalendarImporter::Exceptions::InvalidResponse)
      end
    end
  end
end
