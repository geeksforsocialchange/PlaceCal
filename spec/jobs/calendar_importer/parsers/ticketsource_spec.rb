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
      expect(described_class::DOMAINS).to eq(%w[www.ticketsource.co.uk ticketsource.co.uk www.ticketsource.com ticketsource.com])
    end
  end

  describe ".requires_api_token?" do
    it "returns true (API-based parser)" do
      expect(described_class.requires_api_token?).to be(true)
    end
  end

  describe ".allowlist_pattern" do
    it "matches www.ticketsource.co.uk venue pages" do
      url = "https://www.ticketsource.co.uk/fairfield-house"
      expect(url).to match(described_class.allowlist_pattern)
    end

    it "matches ticketsource.co.uk venue pages without www" do
      url = "https://ticketsource.co.uk/some-venue"
      expect(url).to match(described_class.allowlist_pattern)
    end

    it "matches www.ticketsource.com venue pages" do
      url = "https://www.ticketsource.com/mcr-balfolk"
      expect(url).to match(described_class.allowlist_pattern)
    end

    it "matches ticketsource.com venue pages without www" do
      url = "https://ticketsource.com/mcr-balfolk/"
      expect(url).to match(described_class.allowlist_pattern)
    end

    it "matches venue pages with trailing slash" do
      url = "https://www.ticketsource.co.uk/fairfield-house/"
      expect(url).to match(described_class.allowlist_pattern)
    end

    it "does not match event subpages" do
      url = "https://www.ticketsource.co.uk/fairfield-house/event/e-xxxxx"
      expect(url).not_to match(described_class.allowlist_pattern)
    end

    it "does not match non-ticketsource URLs" do
      url = "https://www.example.com/fairfield-house"
      expect(url).not_to match(described_class.allowlist_pattern)
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

      let(:dates_url) { "https://api.ticketsource.io/events/evt_123/dates?page=1&per_page=100" }
      let(:venues_url) { "https://api.ticketsource.io/events/evt_123/venues" }
      let(:venues_response) do
        {
          "data" => [
            {
              "id" => "ven_789",
              "attributes" => {
                "name" => "Fairfield House",
                "capacity" => 120,
                "address" => { "line_1" => "10 High Street", "line_3" => "Bath", "postcode" => "BA1 5AH", "latitude" => 51.38 }
              }
            }
          ]
        }.to_json
      end

      def dates_page(*ids, next_link: nil)
        {
          "data" => ids.map { |id| { "id" => id, "attributes" => { "start" => "2026-03-15T19:30:00+00:00" } } },
          "links" => { "next" => next_link }
        }.to_json
      end

      before do
        stub_request(:get, dates_url)
          .to_return(status: 200, body: dates_page("date_1"), headers: { "Content-Type" => "application/json" })
        stub_request(:get, venues_url)
          .to_return(status: 200, body: venues_response, headers: { "Content-Type" => "application/json" })
      end

      it "fetches events from the API with their dates" do
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })

        parser = described_class.new(calendar)
        data = parser.download_calendar

        expect(data).to be_an(Array)
        expect(data.length).to eq(1)
        expect(data.first["id"]).to eq("evt_123")
        expect(data.first["dates"].pluck("id")).to eq(["date_1"])
      end

      it "keeps only the fields the importer reads in the downloaded records" do
        noisy_event = JSON.parse(events_response)
        noisy_event["data"].first["attributes"]["tickets_sold"] = 40
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: noisy_event.to_json, headers: { "Content-Type" => "application/json" })
        noisy_date = {
          "id" => "date_1", "type" => "date",
          "attributes" => { "start" => "2026-03-15T19:30:00+00:00", "end" => "2026-03-15T22:00:00+00:00",
                            "cancelled" => false, "tickets_available" => 12, "tickets_sold" => 3 }
        }
        stub_request(:get, dates_url)
          .to_return(status: 200, body: { "data" => [noisy_date] }.to_json, headers: { "Content-Type" => "application/json" })

        expect(described_class.new(calendar).download_calendar).to eq(
          [{
            "id" => "evt_123",
            "name" => "Test Show",
            "description" => "A great show",
            "reference" => "test-show",
            "images" => [],
            "dates" => [{ "id" => "date_1", "start" => "2026-03-15T19:30:00+00:00",
                          "end" => "2026-03-15T22:00:00+00:00", "cancelled" => false }],
            "venue" => { "name" => "Fairfield House", "line_1" => "10 High Street", "line_3" => "Bath", "postcode" => "BA1 5AH" }
          }]
        )
      end

      it "keeps the documented keywords, category, genre and image sources" do
        listing = JSON.parse(events_response)
        listing["data"].first["attributes"].merge!(
          "keywords" => "folk, dance", "category" => "Music", "genre" => "Folk", "terms" => "No refunds",
          "images" => [{ "type" => "header", "src" => "https://cdn.ticketsource.io/a.jpg" }, { "type" => "thumbnail" }]
        )
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: listing.to_json, headers: { "Content-Type" => "application/json" })

        record = described_class.new(calendar).download_calendar.first

        expect(record).to include("keywords" => "folk, dance", "category" => "Music", "genre" => "Folk",
                                  "images" => ["https://cdn.ticketsource.io/a.jpg"])
        expect(record).not_to have_key("terms")
      end

      it "leaves out a date marked not public, and keeps one without the flag" do
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        dates = [
          { "id" => "date_1", "attributes" => { "start" => "2026-03-15T19:30:00+00:00", "public" => true } },
          { "id" => "date_2", "attributes" => { "start" => "2026-03-16T19:30:00+00:00", "public" => false } },
          { "id" => "date_3", "attributes" => { "start" => "2026-03-17T19:30:00+00:00" } }
        ]
        stub_request(:get, dates_url)
          .to_return(status: 200, body: { "data" => dates }.to_json, headers: { "Content-Type" => "application/json" })

        data = described_class.new(calendar).download_calendar

        expect(data.first["dates"].pluck("id")).to eq(%w[date_1 date_3])
      end

      it "raises when an event's venues request fails" do
        allow(CalendarImporter::Parsers::Base).to receive(:sleep)
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, venues_url).to_return(status: 500)

        expect { described_class.new(calendar).download_calendar }.to raise_error(
          CalendarImporter::Exceptions::InaccessibleFeed,
          /code=500/
        )
      end

      it "reads an event whose venues request answers 404 as having no venue" do
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, venues_url).to_return(status: 404)

        data = described_class.new(calendar).download_calendar

        expect(data.first["venue"]).to be_nil
      end

      it "reads every page of an event's dates" do
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, dates_url)
          .to_return(status: 200, body: dates_page("date_1", next_link: "page2"), headers: { "Content-Type" => "application/json" })
        stub_request(:get, "https://api.ticketsource.io/events/evt_123/dates?page=2&per_page=100")
          .to_return(status: 200, body: dates_page("date_2"), headers: { "Content-Type" => "application/json" })

        data = described_class.new(calendar).download_calendar

        expect(data.first["dates"].pluck("id")).to eq(%w[date_1 date_2])
      end

      it "raises when an event's dates request fails" do
        allow(CalendarImporter::Parsers::Base).to receive(:sleep)
        stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
          .to_return(status: 200, body: events_response, headers: { "Content-Type" => "application/json" })
        stub_request(:get, dates_url).to_return(status: 429)

        expect { described_class.new(calendar).download_calendar }.to raise_error(
          CalendarImporter::Exceptions::InaccessibleFeed,
          /rate limit/
        )
      end

      { "archived" => { "archived" => true }, "non-public" => { "public" => false } }.each do |kind, attributes|
        it "leaves out #{kind} events without fetching their dates or venues" do
          listing = JSON.parse(events_response)
          listing["data"].first["attributes"].merge!(attributes)
          stub_request(:get, "https://api.ticketsource.io/events?page=1&per_page=100")
            .to_return(status: 200, body: listing.to_json, headers: { "Content-Type" => "application/json" })

          expect(described_class.new(calendar).download_calendar).to eq([])
          expect(a_request(:get, dates_url)).not_to have_been_made
          expect(a_request(:get, venues_url)).not_to have_been_made
        end
      end

      it "retries a transient 5xx response then succeeds (ApiBase retry path)" do
        allow(CalendarImporter::Parsers::Base).to receive(:sleep) # don't actually back off
        events_url = "https://api.ticketsource.io/events?page=1&per_page=100"
        stub_request(:get, events_url).to_return(
          { status: 503 },
          { status: 200, body: events_response, headers: { "Content-Type" => "application/json" } }
        )

        parser = described_class.new(calendar)
        data = parser.download_calendar

        expect(data.length).to eq(1)
        expect(a_request(:get, events_url)).to have_been_made.twice
        expect(CalendarImporter::Parsers::Base).to have_received(:sleep).once
      end

      it "raises InaccessibleFeed once retries are exhausted on a persistent 5xx" do
        allow(CalendarImporter::Parsers::Base).to receive(:sleep)
        events_url = "https://api.ticketsource.io/events?page=1&per_page=100"
        stub_request(:get, events_url).to_return(status: 503)

        parser = described_class.new(calendar)
        expect { parser.download_calendar }.to raise_error(
          CalendarImporter::Exceptions::InaccessibleFeed,
          /API error \(code=503\)/
        )
        # initial attempt + HTTP_MAX_RETRIES retries
        expect(a_request(:get, events_url))
          .to have_been_made.times(CalendarImporter::Parsers::Base::HTTP_MAX_RETRIES + 1)
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
        "name" => "Test Show",
        "description" => "A great show",
        "reference" => "test-show",
        "dates" => [
          {
            "id" => "date_456",
            "start" => "2026-03-15T19:30:00+00:00",
            "end" => "2026-03-15T22:00:00+00:00",
            "cancelled" => false
          }
        ],
        "venue" => {
          "name" => "Fairfield House",
          "line_1" => "10 High Street",
          "line_2" => "",
          "line_3" => "Bath",
          "line_4" => "",
          "postcode" => "BA1 5AH"
        }
      }
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

    it "links each event under the venue page" do
      event = parser.import_events_from([sample_event_data]).first
      expect(event.publisher_url).to eq("https://www.ticketsource.co.uk/fairfield-house/test-show")
    end

    context "when the source has a trailing slash" do
      let(:url) { "https://www.ticketsource.com/mcr-balfolk/" }

      it "does not double the slash in event links" do
        event = parser.import_events_from([sample_event_data]).first
        expect(event.publisher_url).to eq("https://www.ticketsource.com/mcr-balfolk/test-show")
      end
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

    it "keeps a cancelled date, marked cancelled" do
      cancelled_event = sample_event_data.deep_dup
      cancelled_event["dates"].first["cancelled"] = true

      expect(parser.import_events_from([cancelled_event]).map(&:status)).to eq(["cancelled"])
    end

    it "imports one event per date, cancelled or not" do
      record = sample_event_data.deep_dup
      record["dates"] << { "id" => "date_789", "start" => "2026-03-22T19:30:00+00:00", "cancelled" => true }
      record["dates"] << { "id" => "date_999", "start" => "2026-03-29T19:30:00+00:00" }

      expect(parser.import_events_from([record]).map { [it.uid, it.status] }).to eq(
        [%w[evt_123-date_456 scheduled], %w[evt_123-date_789 cancelled], %w[evt_123-date_999 scheduled]]
      )
    end

    it "imports the event without a location when it has no venue" do
      events = parser.import_events_from([sample_event_data.merge("venue" => nil)])

      expect(events.map(&:uid)).to eq(["evt_123-date_456"])
      expect(events.first.location).to be_nil
    end

    it "returns empty array for nil input" do
      expect(parser.import_events_from(nil)).to eq([])
    end

    it "returns empty array for non-array input" do
      expect(parser.import_events_from("invalid")).to eq([])
    end
  end
end
