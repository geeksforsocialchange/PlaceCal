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

  describe "#extract_wix_events (private)" do
    let(:calendar) { build(:calendar, source: "https://example.wixsite.com/test/events") }
    let(:parser) { described_class.new(calendar) }

    let(:valid_wix_event) do
      {
        "id" => "event-123",
        "title" => "Test Event",
        "scheduling" => { "config" => { "startDate" => "2026-01-17T19:00:00.000Z" } }
      }
    end

    it "extracts events from valid Wix HTML with embedded JSON" do
      html = <<~HTML
        <html>
          <head>
            <script type="application/json">{"events": [#{valid_wix_event.to_json}]}</script>
          </head>
        </html>
      HTML

      events = parser.send(:extract_wix_events, html)
      expect(events).to be_an(Array)
      expect(events.length).to eq(1)
      expect(events.first["title"]).to eq("Test Event")
    end

    it "returns empty array when no script tags present" do
      html = "<html><body><p>No events here</p></body></html>"
      events = parser.send(:extract_wix_events, html)
      expect(events).to eq([])
    end

    it "returns empty array when script tags have invalid JSON" do
      html = <<~HTML
        <html>
          <script type="application/json">{ invalid json }</script>
        </html>
      HTML

      events = parser.send(:extract_wix_events, html)
      expect(events).to eq([])
    end

    it "returns empty array when JSON doesn't contain Wix events" do
      html = <<~HTML
        <html>
          <script type="application/json">{"someOther": "data"}</script>
        </html>
      HTML

      events = parser.send(:extract_wix_events, html)
      expect(events).to eq([])
    end

    it "handles malformed HTML gracefully" do
      html = "<html><script type='application/json'>{\"events\": []"
      events = parser.send(:extract_wix_events, html)
      expect(events).to eq([])
    end

    it "finds events in nested JSON structures" do
      html = <<~HTML
        <html>
          <script type="application/json">
            {"wrapper": {"data": {"events": [#{valid_wix_event.to_json}]}}}
          </script>
        </html>
      HTML

      events = parser.send(:extract_wix_events, html)
      expect(events.length).to eq(1)
      expect(events.first["title"]).to eq("Test Event")
    end
  end

  describe "#find_events_array (private)" do
    let(:calendar) { build(:calendar, source: "https://example.wixsite.com/test/events") }
    let(:parser) { described_class.new(calendar) }

    let(:valid_wix_event) do
      {
        "id" => "event-123",
        "title" => "Test Event",
        "scheduling" => { "config" => { "startDate" => "2026-01-17T19:00:00.000Z" } }
      }
    end

    it "finds events at top level of hash" do
      json = { "events" => [valid_wix_event] }
      result = parser.send(:find_events_array, json)
      expect(result).to eq([valid_wix_event])
    end

    it "finds deeply nested events array" do
      json = {
        "level1" => {
          "level2" => {
            "level3" => {
              "events" => [valid_wix_event]
            }
          }
        }
      }
      result = parser.send(:find_events_array, json)
      expect(result).to eq([valid_wix_event])
    end

    it "respects depth limit to prevent stack overflow" do
      # Build a structure deeper than the 15-level limit
      json = valid_wix_event
      20.times { json = { "nested" => json } }
      json = { "events" => [json] }

      # Should not find events because they're too deeply nested
      result = parser.send(:find_events_array, json, 14)
      expect(result).to be_nil
    end

    it "returns nil for non-hash/non-array input" do
      expect(parser.send(:find_events_array, "string")).to be_nil
      expect(parser.send(:find_events_array, 123)).to be_nil
      expect(parser.send(:find_events_array, nil)).to be_nil
    end

    it "searches through arrays to find nested events" do
      json = [
        { "other" => "data" },
        { "events" => [valid_wix_event] }
      ]
      result = parser.send(:find_events_array, json)
      expect(result).to eq([valid_wix_event])
    end

    it "returns nil when events array contains non-Wix events" do
      non_wix_events = [{ "name" => "Not a Wix event" }]
      json = { "events" => non_wix_events }
      result = parser.send(:find_events_array, json)
      expect(result).to be_nil
    end
  end
end
