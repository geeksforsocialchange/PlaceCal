# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Squarespace do
  describe ".allowlist_pattern" do
    it "matches squarespace.com URLs" do
      pattern = described_class.allowlist_pattern
      expect(pattern).to match("https://example.squarespace.com/events")
      expect(pattern).to match("https://mysite.squarespace.com/calendar")
    end

    it "does not match custom domain URLs" do
      pattern = described_class.allowlist_pattern
      expect(pattern).not_to match("https://www.partisancollective.net/events/listing/")
      expect(pattern).not_to match("https://example.com/events")
    end
  end

  describe ".handles_url?" do
    it "returns true for squarespace.com URLs" do
      calendar = build(:calendar, source: "https://example.squarespace.com/events")
      expect(described_class.handles_url?(calendar)).to be true
    end

    it "returns true for custom domain Squarespace sites with events" do
      html = <<~HTML
        <html>
          <head>
            <!-- This is Squarespace. -->
          </head>
          <body></body>
        </html>
      HTML

      json_response = { "upcoming" => [{ "id" => "123", "title" => "Test Event" }] }.to_json

      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/events")
        .and_return(html)
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/events?format=json")
        .and_return(json_response)

      calendar = build(:calendar, source: "https://www.example-squarespace.com/events")
      expect(described_class.handles_url?(calendar)).to be true
    end

    it "returns true for Squarespace sites with only past events" do
      html = <<~HTML
        <html>
          <head>
            <!-- This is Squarespace. -->
          </head>
          <body></body>
        </html>
      HTML

      json_response = { "past" => [{ "id" => "123", "title" => "Past Event" }] }.to_json

      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/events")
        .and_return(html)
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/events?format=json")
        .and_return(json_response)

      calendar = build(:calendar, source: "https://www.example-squarespace.com/events")
      expect(described_class.handles_url?(calendar)).to be true
    end

    it "returns false for non-Squarespace sites" do
      html = '<html><head><meta name="generator" content="WordPress"></head></html>'
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(html)

      calendar = build(:calendar, source: "https://example.com/events")
      expect(described_class.handles_url?(calendar)).to be false
    end

    it "returns false when HTTP request fails" do
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .and_raise(CalendarImporter::Exceptions::InaccessibleFeed, "Not found")

      calendar = build(:calendar, source: "https://example.com/events")
      expect(described_class.handles_url?(calendar)).to be false
    end

    it "returns false for Squarespace sites without events" do
      html = <<~HTML
        <html>
          <head>
            <!-- This is Squarespace. -->
          </head>
          <body></body>
        </html>
      HTML

      json_response = { "collection" => { "title" => "Blog" } }.to_json

      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/blog")
        .and_return(html)
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://www.example-squarespace.com/blog?format=json")
        .and_return(json_response)

      calendar = build(:calendar, source: "https://www.example-squarespace.com/blog")
      expect(described_class.handles_url?(calendar)).to be false
    end
  end

  describe ".squarespace_site?" do
    it "returns true for pages with Squarespace marker and events" do
      html = <<~HTML
        <html>
          <head>
            <!-- This is Squarespace. -->
          </head>
          <body></body>
        </html>
      HTML

      json_response = { "upcoming" => [{ "id" => "123" }] }.to_json

      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://example.com/events")
        .and_return(html)
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://example.com/events?format=json")
        .and_return(json_response)

      expect(described_class.squarespace_site?("https://example.com/events")).to be true
    end

    it "returns false for pages without Squarespace marker" do
      html = "<html><head></head><body></body></html>"
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(html)

      expect(described_class.squarespace_site?("https://example.com")).to be false
    end
  end

  describe ".squarespace_events?" do
    it "returns true when JSON contains upcoming events" do
      json_response = { "upcoming" => [{ "id" => "123" }] }.to_json
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(json_response)

      expect(described_class.squarespace_events?("https://example.com/events")).to be true
    end

    it "returns true when JSON contains past events" do
      json_response = { "past" => [{ "id" => "123" }] }.to_json
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(json_response)

      expect(described_class.squarespace_events?("https://example.com/events")).to be true
    end

    it "returns false when JSON has no events" do
      json_response = { "collection" => {} }.to_json
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return(json_response)

      expect(described_class.squarespace_events?("https://example.com/events")).to be false
    end

    it "returns false when JSON is invalid" do
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source).and_return("not json")

      expect(described_class.squarespace_events?("https://example.com/events")).to be false
    end

    it "handles URLs with existing query parameters" do
      json_response = { "upcoming" => [{ "id" => "123" }] }.to_json
      allow(CalendarImporter::Parsers::Base).to receive(:read_http_source)
        .with("https://example.com/events?page=1&format=json")
        .and_return(json_response)

      expect(described_class.squarespace_events?("https://example.com/events?page=1")).to be true
    end
  end

  describe "#import_events_from" do
    let(:calendar) { build(:calendar, source: "https://example.squarespace.com/events") }
    let(:parser) { described_class.new(calendar) }

    let(:squarespace_data) do
      {
        "website" => { "baseUrl" => "https://example.com" },
        "collection" => { "fullUrl" => "/events" },
        "upcoming" => [
          {
            "id" => "event-123",
            "title" => "Test Event",
            "body" => "<p>Description</p>",
            "startDate" => 1_769_538_600_571,
            "endDate" => 1_769_547_600_571
          }
        ]
      }
    end

    it "converts Squarespace data to SquarespaceEvent objects" do
      events = parser.import_events_from(squarespace_data)

      expect(events.length).to eq(1)
      expect(events.first).to be_a(CalendarImporter::Events::SquarespaceEvent)
    end

    it "returns empty array when data has no upcoming events" do
      data = { "website" => {}, "collection" => {} }
      events = parser.import_events_from(data)

      expect(events).to eq([])
    end

    it "returns empty array when data is not a hash" do
      expect(parser.import_events_from(nil)).to eq([])
      expect(parser.import_events_from([])).to eq([])
      expect(parser.import_events_from("string")).to eq([])
    end
  end
end
