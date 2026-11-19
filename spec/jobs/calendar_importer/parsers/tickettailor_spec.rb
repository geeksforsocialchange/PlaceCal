# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Tickettailor do
  describe "constants" do
    it "has the correct NAME" do
      expect(described_class::NAME).to eq("Ticket Tailor")
    end

    it "has the correct KEY" do
      expect(described_class::KEY).to eq("tickettailor")
    end

    it "has the correct DOMAINS" do
      expect(described_class::DOMAINS).to eq(%w[www.tickettailor.com tickettailor.com])
    end

    it "requires an API token" do
      expect(described_class.requires_api_token?).to be true
    end
  end

  describe ".allowlist_pattern" do
    it "matches www.tickettailor.com event pages" do
      expect(described_class.allowlist_pattern).to match("https://www.tickettailor.com/events/queerrunclub")
    end

    it "matches tickettailor.com event pages without www" do
      expect(described_class.allowlist_pattern).to match("https://tickettailor.com/events/some-org")
    end

    it "matches event pages with trailing slash" do
      expect(described_class.allowlist_pattern).to match("https://www.tickettailor.com/events/queerrunclub/")
    end

    it "does not match individual event pages" do
      expect(described_class.allowlist_pattern).not_to match("https://www.tickettailor.com/events/queerrunclub/12345")
    end

    it "does not match non-tickettailor URLs" do
      expect(described_class.allowlist_pattern).not_to match("https://www.example.com/events/queerrunclub")
    end
  end

  describe ".handles_url?" do
    it "returns truthy for valid TicketTailor box office URLs" do
      calendar = build(:calendar, source: "https://www.tickettailor.com/events/queerrunclub")
      expect(described_class).to be_handles_url(calendar)
    end

    it "returns falsy for non-TicketTailor URLs" do
      calendar = build(:calendar, source: "https://www.example.com/events")
      expect(described_class).not_to be_handles_url(calendar)
    end
  end

  describe "#download_calendar" do
    let(:url) { "https://www.tickettailor.com/events/testorg" }

    context "without API key" do
      let(:calendar) { build(:calendar, source: url, api_token: nil) }

      it "raises an error when API key is missing" do
        parser = described_class.new(calendar)
        expect { parser.download_calendar }.to raise_error(
          CalendarImporter::Exceptions::InaccessibleFeed,
          /API key required/
        )
      end
    end

    context "with API key" do
      let(:api_key) { "sk_test_placeholder" }
      let(:calendar) { build(:calendar, source: url, api_token: api_key) }

      it "fetches events from the API" do
        VCR.use_cassette("tickettailor_events", match_requests_on: %i[method uri]) do
          parser = described_class.new(calendar)
          data = parser.download_calendar

          expect(data).to be_an(Array)
          expect(data.length).to eq(16)
          expect(data.first).to include("id", "name", "status")
        end
      end
    end
  end

  describe "#import_events_from" do
    let(:url) { "https://www.tickettailor.com/events/testorg" }
    let(:calendar) { build(:calendar, source: url, api_token: "test_key") }
    let(:parser) { described_class.new(calendar) }

    let(:sample_event_data) do
      {
        "id" => "ev_123456",
        "name" => "Test Event",
        "description" => "A test event description",
        "timezone" => "Europe/London",
        "start" => {
          "date" => "2026-06-15",
          "formatted" => "Mon 15 Jun 2026 2:00 PM",
          "iso" => "2026-06-15T14:00:00+01:00",
          "time" => "14:00",
          "timezone" => "+01:00",
          "unix" => 1_781_528_400
        },
        "end" => {
          "date" => "2026-06-15",
          "formatted" => "Mon 15 Jun 2026 5:00 PM",
          "iso" => "2026-06-15T17:00:00+01:00",
          "time" => "17:00",
          "timezone" => "+01:00",
          "unix" => 1_781_539_200
        },
        "venue" => {
          "name" => "Test Venue",
          "postal_code" => "M1 1AA"
        },
        "url" => "https://www.tickettailor.com/events/testorg/123456",
        "status" => "published"
      }
    end

    it "converts raw data to TickettailorEvent objects" do
      events = parser.import_events_from([sample_event_data])

      expect(events).to be_an(Array)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(CalendarImporter::Events::TickettailorEvent)
    end

    it "extracts event fields correctly" do
      events = parser.import_events_from([sample_event_data])
      event = events.first

      expect(event.uid).to eq("ev_123456")
      expect(event.summary).to eq("Test Event")
      expect(event.description).to eq("A test event description")
      expect(event.location).to eq("Test Venue, M1 1AA")
      expect(event.publisher_url).to eq("https://www.tickettailor.com/events/testorg/123456")
    end

    it "parses start and end times at their UTC offset" do
      event = parser.import_events_from([sample_event_data]).first

      expect(event.dtstart).to eq(Time.utc(2026, 6, 15, 13, 0))
      expect(event.dtend).to eq(Time.utc(2026, 6, 15, 16, 0))
    end

    it "reads a time without an iso field in the event's timezone" do
      data = sample_event_data.merge("timezone" => "Europe/Paris", "start" => { "date" => "2026-06-15", "time" => "14:00" })

      expect(parser.import_events_from([data]).first.dtstart).to eq(Time.utc(2026, 6, 15, 12, 0))
    end

    it "keeps the recorded events at their London times, in summer and winter", :aggregate_failures do
      events = VCR.use_cassette("tickettailor_events", match_requests_on: %i[method uri]) do
        parser.import_events_from(described_class.new(calendar).download_calendar)
      end
      summer = events.find { it.uid == "ev_4668136" }
      winter = events.find { it.uid == "ev_4739593" }

      expect(summer.dtstart).to eq(Time.utc(2024, 10, 12, 9, 0))
      expect(summer.dtstart.in_time_zone("Europe/London").strftime("%H:%M")).to eq("10:00")
      expect(winter.dtstart).to eq(Time.utc(2024, 11, 16, 10, 0))
      expect(winter.dtend).to eq(Time.utc(2024, 11, 16, 12, 30))
    end

    it "filters out non-published events" do
      draft_event = sample_event_data.merge("status" => "draft")
      events = parser.import_events_from([sample_event_data, draft_event])

      expect(events.length).to eq(1)
    end

    it "returns empty array for nil input" do
      expect(parser.import_events_from(nil)).to eq([])
    end

    it "returns empty array for non-array input" do
      expect(parser.import_events_from("invalid")).to eq([])
    end
  end
end
