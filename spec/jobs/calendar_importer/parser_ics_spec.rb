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

    context "when one event's dates can't be read" do
      let(:ics_data) do
        <<~ICS
          BEGIN:VCALENDAR
          VERSION:2.0
          BEGIN:VEVENT
          UID:broken@example.com
          DTSTART:2026-11-0X
          SUMMARY:Broken
          END:VEVENT
          BEGIN:VEVENT
          UID:good@example.com
          DTSTART;TZID=Europe/London:20261105T190000
          DTEND;TZID=Europe/London:20261105T200000
          SUMMARY:Good
          END:VEVENT
          END:VCALENDAR
        ICS
      end

      it "keeps the other events and notes the skipped one" do
        events = parser.parse_remote_calendars(ics_data).flat_map(&:events)

        expect(events.map { |event| event.summary.to_s }).to eq(["Good"])
        expect(parser.notices).to eq(['Skipped "Broken" because its dates could not be read (Failed to parse "2026-11-0X" - invalid date).'])
      end

      it "passes the notice on with the parsed events" do
        calendar = create(:ics_calendar)
        stub_request(:get, calendar.source).to_return(status: 200, body: ics_data)

        output = described_class.new(calendar, force_import: true).calendar_to_events

        expect(output.events.map(&:summary)).to eq(["Good"])
        expect(output.notices).to eq(['Skipped "Broken" because its dates could not be read (Failed to parse "2026-11-0X" - invalid date).'])
      end

      it "imports the other events and records the notice on the calendar" do
        Timecop.freeze(Time.zone.local(2026, 10, 29, 12))
        calendar = create(:ics_calendar, strategy: "no_location", importer_mode: "ical", calendar_state: "in_worker")
        stub_request(:get, calendar.source).to_return(status: 200, body: ics_data)

        CalendarImporter::CalendarImporterTask.new(calendar, Time.current, true).run

        expect(calendar.events.pluck(:summary)).to eq(["Good"])
        expect(calendar.reload.calendar_state).to eq("idle")
        expect(calendar.notices).to eq(['Skipped "Broken" because its dates could not be read (Failed to parse "2026-11-0X" - invalid date).'])
      end
    end

    it "fails the feed when a date outside an event can't be read" do
      ics_data = <<~ICS
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VTIMEZONE
        TZID:Somewhere
        BEGIN:STANDARD
        DTSTART:1601-01-0X
        TZOFFSETFROM:+0100
        TZOFFSETTO:+0000
        END:STANDARD
        END:VTIMEZONE
        END:VCALENDAR
      ICS

      expect { parser.parse_remote_calendars(ics_data) }
        .to raise_error(CalendarImporter::Exceptions::InvalidResponse, /Could not parse ICS response \(Failed to parse "1601-01-0X"/)
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
