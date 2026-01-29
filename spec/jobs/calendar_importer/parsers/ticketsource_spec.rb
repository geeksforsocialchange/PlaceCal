# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Ticketsource do
  describe "constants" do
    it "has the correct NAME" do
      expect(described_class::NAME).to eq("TicketSource")
    end

    it "has the correct KEY" do
      expect(described_class::KEY).to eq("ticketsource")
    end

    it "has the correct DOMAINS" do
      expect(described_class::DOMAINS).to eq(%w[www.ticketsource.co.uk ticketsource.co.uk])
    end
  end

  describe ".skip_source_validation?" do
    it "returns true (API-based parser)" do
      expect(described_class.skip_source_validation?).to be(true)
    end
  end

  describe ".allowlist_pattern" do
    it "matches www.ticketsource.co.uk venue pages" do
      expect(described_class.allowlist_pattern).to match("https://www.ticketsource.co.uk/fairfield-house")
    end

    it "matches ticketsource.co.uk venue pages without www" do
      expect(described_class.allowlist_pattern).to match("https://ticketsource.co.uk/some-venue")
    end

    it "matches venue pages with trailing slash" do
      expect(described_class.allowlist_pattern).to match("https://www.ticketsource.co.uk/fairfield-house/")
    end

    it "does not match event subpages" do
      expect(described_class.allowlist_pattern).not_to match("https://www.ticketsource.co.uk/fairfield-house/event/e-xxxxx")
    end

    it "does not match non-ticketsource URLs" do
      expect(described_class.allowlist_pattern).not_to match("https://www.example.com/fairfield-house")
    end
  end

  describe ".handles_url?" do
    it "returns truthy for valid TicketSource venue URLs" do
      calendar = build(:calendar, source: "https://www.ticketsource.co.uk/fairfield-house")
      expect(described_class).to be_handles_url(calendar)
    end

    it "returns falsy for non-TicketSource URLs" do
      calendar = build(:calendar, source: "https://www.example.com/events")
      expect(described_class).not_to be_handles_url(calendar)
    end
  end

  describe "#download_calendar" do
    let(:url) { "https://www.ticketsource.co.uk/fairfield-house" }

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
      let(:api_key) { "test_api_key_placeholder" }
      let(:calendar) { build(:calendar, source: url, api_token: api_key) }

      let(:events_response) do
        {
          "data" => [
            {
              "id" => "evt_123",
              "type" => "event",
              "attributes" => {
                "name" => "Test Show",
                "description" => "A great show",
                "reference" => "test-show",
                "activated" => true,
                "archived" => false,
                "public" => true
              }
            }
          ],
          "links" => { "next" => nil },
          "meta" => { "current_page" => 1, "last_page" => 1 }
        }.to_json
      end

      it "fetches events from the API" do
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })

        parser = described_class.new(calendar)
        data = parser.download_calendar

        expect(data).to be_an(Array)
        expect(data.length).to eq(1)
        expect(data.first["id"]).to eq("evt_123")
      end
    end
  end

  describe "#import_events_from" do
    let(:url) { "https://www.ticketsource.co.uk/fairfield-house" }
    let(:calendar) { build(:calendar, source: url, api_token: "test_key") }
    let(:parser) { described_class.new(calendar) }

    let(:sample_event_data) do
      {
        "id" => "evt_123",
        "type" => "event",
        "attributes" => {
          "name" => "Test Show",
          "description" => "A great show",
          "reference" => "test-show",
          "archived" => false,
          "public" => true
        }
      }
    end

    let(:dates_response) do
      {
        "data" => [
          {
            "id" => "date_456",
            "attributes" => {
              "start" => "2026-03-15T19:30:00+00:00",
              "end" => "2026-03-15T22:00:00+00:00",
              "cancelled" => false
            }
          }
        ]
      }.to_json
    end

    let(:venues_response) do
      {
        "data" => [
          {
            "id" => "ven_789",
            "attributes" => {
              "name" => "Fairfield House",
              "address" => {
                "line_1" => "10 High Street",
                "line_2" => "",
                "line_3" => "Bath",
                "line_4" => "",
                "postcode" => "BA1 5AH"
              }
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, %r{api\.ticketsource\.io/events/evt_123/dates})
        .to_return(status: 200, body: dates_response, headers: { "Content-Type" => "application/json" })
      stub_request(:get, %r{api\.ticketsource\.io/events/evt_123/venues})
        .to_return(status: 200, body: venues_response, headers: { "Content-Type" => "application/json" })
    end

    it "converts raw data to TicketsourceEvent objects" do
      events = parser.import_events_from([sample_event_data])

      expect(events).to be_an(Array)
      expect(events.length).to eq(1)
      expect(events.first).to be_a(CalendarImporter::Events::TicketsourceEvent)
    end

    it "extracts event fields correctly" do
      events = parser.import_events_from([sample_event_data])
      event = events.first

      expect(event.uid).to eq("evt_123-date_456")
      expect(event.summary).to eq("Test Show")
      expect(event.description).to eq("A great show")
      expect(event.location).to eq("Fairfield House, 10 High Street, Bath, BA1 5AH")
    end

    it "parses start and end times correctly" do
      events = parser.import_events_from([sample_event_data])
      event = events.first

      expect(event.dtstart).to be_present
      expect(event.dtstart.year).to eq(2026)
      expect(event.dtstart.month).to eq(3)
      expect(event.dtstart.day).to eq(15)
      expect(event.dtstart.hour).to eq(19)

      expect(event.dtend).to be_present
      expect(event.dtend.hour).to eq(22)
    end

    it "filters out cancelled dates" do
      cancelled_dates_response = {
        "data" => [
          {
            "id" => "date_456",
            "attributes" => {
              "start" => "2026-03-15T19:30:00+00:00",
              "end" => "2026-03-15T22:00:00+00:00",
              "cancelled" => true
            }
          }
        ]
      }.to_json

      stub_request(:get, %r{api\.ticketsource\.io/events/evt_123/dates})
        .to_return(status: 200, body: cancelled_dates_response, headers: { "Content-Type" => "application/json" })

      events = parser.import_events_from([sample_event_data])
      expect(events).to be_empty
    end

    it "filters out archived events" do
      archived_event = sample_event_data.deep_dup
      archived_event["attributes"]["archived"] = true

      events = parser.import_events_from([archived_event])
      expect(events).to be_empty
    end

    it "filters out non-public events" do
      private_event = sample_event_data.deep_dup
      private_event["attributes"]["public"] = false

      events = parser.import_events_from([private_event])
      expect(events).to be_empty
    end

    it "returns empty array for nil input" do
      expect(parser.import_events_from(nil)).to eq([])
    end

    it "returns empty array for non-array input" do
      expect(parser.import_events_from("invalid")).to eq([])
    end
  end
end
