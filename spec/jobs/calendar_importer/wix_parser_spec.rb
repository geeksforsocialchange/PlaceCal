# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Wix do
  describe ".allowlist_pattern" do
    it "matches wixsite.com event URLs" do
      pattern = described_class.allowlist_pattern
      expect(pattern).to match("https://user123.wixsite.com/mysite/events")
      expect(pattern).to match("https://user123.wixsite.com/mysite/event/some-event")
      expect(pattern).to match("https://example.wixsite.com/community")
    end

    it "does not match non-wix URLs" do
      pattern = described_class.allowlist_pattern
      expect(pattern).not_to match("https://example.com/events")
      expect(pattern).not_to match("https://www.socialrefuge.com/event-list")
    end
  end

  describe "#download_calendar" do
    it "extracts events from Wix page HTML" do
      wix_url = "https://www.socialrefuge.com/event-list"

      VCR.use_cassette(:wix_events) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :wix_test_calendar,
          source: wix_url,
          importer_mode: "wix"
        )

        parser = described_class.new(calendar)
        data = parser.download_calendar

        expect(data).to be_an(Array)
        expect(data).not_to be_empty
        expect(data.first).to include("id", "title", "scheduling")
      end
    end
  end

  describe "#import_events_from" do
    let(:wix_data) do
      [
        {
          "id" => "event-123",
          "title" => "Test Event",
          "description" => "A test event",
          "slug" => "test-event",
          "scheduling" => {
            "config" => {
              "startDate" => "2026-01-17T19:00:00.000Z",
              "endDate" => "2026-01-17T23:00:00.000Z",
              "timeZoneId" => "Europe/London",
              "scheduleTbd" => false
            }
          },
          "location" => {
            "name" => "Test Venue",
            "address" => "123 Test Street",
            "fullAddress" => {
              "formattedAddress" => "123 Test Street, Manchester M1 1AA, UK"
            }
          }
        }
      ]
    end

    it "converts Wix data to WixEvent objects" do
      calendar = build(:calendar, source: "https://example.wixsite.com/test/events")
      parser = described_class.new(calendar)
      events = parser.import_events_from(wix_data)

      expect(events.length).to eq(1)
      expect(events.first).to be_a(CalendarImporter::Events::WixEvent)
      expect(events.first.summary).to eq("Test Event")
    end

    it "skips events with scheduleTbd set to true" do
      tbd_data = [
        {
          "id" => "tbd-event",
          "title" => "TBD Event",
          "scheduling" => {
            "config" => {
              "scheduleTbd" => true
            }
          }
        }
      ]

      calendar = build(:calendar, source: "https://example.wixsite.com/test/events")
      parser = described_class.new(calendar)
      events = parser.import_events_from(tbd_data)

      expect(events).to be_empty
    end

    it "returns empty array when data is not an array" do
      calendar = build(:calendar, source: "https://example.wixsite.com/test/events")
      parser = described_class.new(calendar)

      expect(parser.import_events_from(nil)).to eq([])
      expect(parser.import_events_from({})).to eq([])
      expect(parser.import_events_from("string")).to eq([])
    end
  end
end
