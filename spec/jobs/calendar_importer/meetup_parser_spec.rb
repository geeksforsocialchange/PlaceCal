# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Meetup do
  describe "#download_calendar" do
    it "downloads iCal data from meetup group URL" do
      meetup_url = "https://www.meetup.com/london-bisexual-women-games-wine-group"

      VCR.use_cassette(:meetup_ical) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: meetup_url
        )

        parser = described_class.new(calendar, url: meetup_url)

        data = parser.download_calendar
        expect(data).to include("BEGIN:VCALENDAR")
        expect(data).to include("BEGIN:VEVENT")
      end
    end

    it "parses events from iCal data" do
      meetup_url = "https://www.meetup.com/london-bisexual-women-games-wine-group"

      VCR.use_cassette(:meetup_ical) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: meetup_url
        )

        parser = described_class.new(calendar, url: meetup_url)

        data = parser.download_calendar
        events = parser.import_events_from(data)

        expect(events).not_to be_empty
        expect(events.first.summary).to be_present
        expect(events.first.dtstart).to be_a(DateTime)
      end
    end

    it "handles non-existent groups" do
      bad_url = "https://www.meetup.com/this-group-does-not-exist-xyz123"

      VCR.use_cassette(:meetup_not_found) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: bad_url
        )

        parser = described_class.new(calendar, url: bad_url)

        expect do
          parser.download_calendar
        end.to raise_error(CalendarImporter::Exceptions::InaccessibleFeed)
      end
    end
  end
end
