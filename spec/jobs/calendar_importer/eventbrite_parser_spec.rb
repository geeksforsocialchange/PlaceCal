# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Eventbrite do
  let(:source_url) { "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483" }
  let(:calendar) do
    build(:calendar, strategy: :event, name: :import_test_calendar, source: source_url)
      .tap { |c| allow(c).to receive(:check_source_reachable) }
  end
  let(:parser) { described_class.new(calendar) }
  let(:max_retries) { CalendarImporter::Parsers::Base::HTTP_MAX_RETRIES }
  let(:api) { "https://www.eventbriteapi.com/v3" }
  let(:organiser_api) { "#{api}/organizers/48062165483/" }

  def events_page_url(page) = "#{api}/organizers/48062165483/events/?expand=venue&page=#{page}"

  def description_url(id) = "#{api}/events/#{id}/description/"

  def api_event(id)
    { "id" => id, "name" => { "text" => "Event #{id}" }, "description" => { "text" => "Short", "html" => "Short" },
      "url" => "https://www.eventbrite.co.uk/e/#{id}", "start" => { "utc" => "2030-01-01T18:00:00Z" },
      "end" => { "utc" => "2030-01-01T20:00:00Z" }, "online_event" => false }
  end

  def events_page(page, ids, page_count:, **pagination)
    body = { pagination: { page_number: page, page_count:, **pagination }, events: ids.map { api_event(it) } }
    { status: 200, body: body.to_json }
  end

  def description(html) = { status: 200, body: { description: html }.to_json }

  before { allow(CalendarImporter::Parsers::Base).to receive(:sleep) }

  describe "#download_calendar" do
    it "extracts events from Eventbrite calendars" do
      VCR.use_cassette(:eventbrite_events) do
        records = parser.download_calendar

        expect(records).to be_a(Array)
        expect(records.count).to eq(72)
      end
    end

    it "reads the recorded calendar when Eventbrite had answered a 504 earlier" do
      VCR.use_cassette(:eventbrite_bad_gateway) do
        expect { parser.download_calendar }.not_to raise_error
      end
    end

    it "gives the same event attributes from the recorded calendar", :aggregate_failures do
      events = VCR.use_cassette(:eventbrite_events) { parser.calendar_to_events.events }
      event = events.find { it.uid == "1353247763489" }

      expect(event.summary).to eq("Write That Novel: A writers workshop")
      expect(event.description).to start_with("<div>AfroQueer & Queer Lit present 'Write That Novel")
      expect(event.dtstart).to eq(DateTime.parse("2025-06-07T14:00:00Z"))
      expect(event.dtend).to eq(DateTime.parse("2025-06-07T16:00:00Z"))
      expect(event.location).to eq("Social Refuge, 27 Great Ancoats Street, Ancoats, England, M4 5AJ")
      expect(event.publisher_url).to eq("https://www.eventbrite.co.uk/e/write-that-novel-a-writers-workshop-tickets-1353247763489")
      expect(event.image_url).to start_with("https://img.evbuc.com/https%3A%2F%2Fcdn.evbuc.com%2Fimages%2F1023300663%2F")
      expect(event.price_from).to eq(0)
      expect(event.online_event_id).to be_nil
      expect(events.map(&:price_from).count(0)).to eq(13)
    end

    it "follows the pages and fills each event's full description" do
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1 2], page_count: 2))
      stub_request(:get, events_page_url(2)).to_return(events_page(2, %w[3], page_count: 2))
      %w[1 2 3].each { stub_request(:get, description_url(it)).to_return(description("<p>Full #{it}</p>")) }

      events = parser.download_calendar

      expect(events.pluck("id")).to eq(%w[1 2 3])
      expect(events.map { it.dig("description", "html") }).to eq(["<p>Full 1</p>", "<p>Full 2</p>", "<p>Full 3</p>"])
      expect(a_request(:get, %r{/events/\?expand=venue})).to have_been_made.twice
    end

    it "sends the server's token" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("EVENTBRITE_TOKEN", nil).and_return("test-token")
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      stub_request(:get, events_page_url(1)).to_return(events_page(1, [], page_count: 1))

      parser.download_calendar

      expect(a_request(:get, events_page_url(1)).with(headers: { "Authorization" => "Bearer test-token" })).to have_been_made
    end

    it "raises InaccessibleFeed when the Eventbrite organiser no longer exists" do
      stub_request(:get, organiser_api).to_return(status: 404, body: { error: "NOT_FOUND" }.to_json)

      expect { parser.download_calendar }
        .to raise_error(CalendarImporter::Exceptions::InaccessibleFeed,
                        "Eventbrite organiser 48062165483 not found (requested object was not found)")
    end

    it "raises InvalidResponse for a body that isn't JSON" do
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      stub_request(:get, events_page_url(1)).to_return(status: 200, body: "<html>Service page</html>")

      expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse)
    end

    it "raises InvalidResponse when the page count is missing, rather than reading one page as the whole list" do
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      stub_request(:get, events_page_url(1)).to_return(status: 200, body: { pagination: {}, events: [api_event("1")] }.to_json)

      expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse)
    end

    it "raises InvalidResponse for JSON without an events list" do
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      stub_request(:get, events_page_url(1)).to_return(status: 200, body: { pagination: { page_count: 1 } }.to_json)

      expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse)
    end

    it "lets a timeout through for the importer job to mark the source unreachable" do
      stub_request(:get, organiser_api).to_timeout

      expect { parser.download_calendar }.to raise_error(Net::OpenTimeout)
    end

    context "when the list may be incomplete" do
      before { stub_request(:get, organiser_api).to_return(status: 200, body: "{}") }

      it "imports a complete two-page feed" do
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1 2], page_count: 2, object_count: 3, has_more_items: true))
        stub_request(:get, events_page_url(2)).to_return(events_page(2, %w[3], page_count: 2, object_count: 3, has_more_items: false))
        stub_request(:get, %r{/description/\z}).to_return(description("<p>Full</p>"))

        expect(parser.download_calendar.pluck("id")).to eq(%w[1 2 3])
      end

      it "returns no events for an organiser with none" do
        stub_request(:get, events_page_url(1)).to_return(events_page(1, [], page_count: 0, object_count: 0, has_more_items: false))

        expect(parser.download_calendar).to eq([])
      end

      it "raises InvalidResponse when the last page says more events follow" do
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1], page_count: 1, has_more_items: true))

        expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse, /more events/)
      end

      it "raises InvalidResponse when the page count changes while the list is read" do
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1], page_count: 2))
        stub_request(:get, events_page_url(2)).to_return(events_page(2, %w[2], page_count: 3))

        expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse, /page count/)
      end

      it "raises InvalidResponse when fewer events arrive than the first page counted" do
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1], page_count: 2, object_count: 4))
        stub_request(:get, events_page_url(2)).to_return(events_page(2, %w[2], page_count: 2, object_count: 4))

        expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::InvalidResponse, /2 of 4/)
      end
    end

    it "raises ApiError for a redirect without following it" do
      stub_request(:get, organiser_api).to_return(status: 302, headers: { "Location" => "https://elsewhere.example/" })

      expect { parser.download_calendar }.to raise_error(described_class::ApiError, /HTTP 302/)
      expect(a_request(:get, "https://elsewhere.example/")).not_to have_been_made
    end

    it "skips an event with no title as invalid and imports the rest" do
      stub_request(:get, source_url).to_return(status: 200, body: "<html></html>")
      stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
      untitled = api_event("2").except("name", "description")
      body = { pagination: { page_number: 1, page_count: 1 }, events: [api_event("1"), untitled] }
      stub_request(:get, events_page_url(1)).to_return(status: 200, body: body.to_json)
      stub_request(:get, %r{/description/\z}).to_return(status: 200, body: { description: nil }.to_json)
      saved = create(:calendar, source: source_url, strategy: "no_location", importer_mode: "eventbrite")
      saved.update!(calendar_state: "in_worker")

      CalendarImporter::CalendarImporterTask.new(saved, Time.zone.today, true).run

      expect(saved.reload.calendar_state).to eq("idle")
      expect(saved.events.pluck(:summary)).to eq(["Event 1"])
    end

    [401, 403].each do |status|
      it "raises without retrying when Eventbrite answers #{status}" do
        stub_request(:get, organiser_api).to_return(status:, body: "{}")

        expect { parser.download_calendar }.to raise_error(described_class::ApiError, /HTTP #{status}/)
        expect(a_request(:get, organiser_api)).to have_been_made.once
      end
    end

    context "when Eventbrite's API returns transient errors" do
      [429, 500, 502, 503, 504].each do |status|
        it "retries the organiser on #{status} and skips the import when it keeps failing" do
          stub_request(:get, organiser_api).to_return(status:, body: "")

          expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::SourceUnavailable)
          expect(a_request(:get, organiser_api)).to have_been_made.times(max_retries + 1)
          expect(CalendarImporter::Parsers::Base).to have_received(:sleep).exactly(max_retries).times
        end
      end

      [Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EPIPE].each do |error|
        it "retries a dropped connection (#{error}) and skips the import when it keeps dropping" do
          stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
          stub_request(:get, events_page_url(1)).to_raise(error)

          expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::SourceUnavailable)
          expect(a_request(:get, events_page_url(1))).to have_been_made.times(max_retries + 1)
        end
      end

      it "skips the import when a later page keeps failing, rather than returning the first page" do
        stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1], page_count: 2))
        stub_request(:get, events_page_url(2)).to_return(status: 502, body: "")

        expect { parser.download_calendar }.to raise_error(CalendarImporter::Exceptions::SourceUnavailable)
        expect(a_request(:get, description_url("1"))).not_to have_been_made
      end

      it "reads the list once Eventbrite recovers" do
        stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
        stub_request(:get, events_page_url(1)).to_return({ status: 503, body: "" }, events_page(1, [], page_count: 1))

        expect(parser.download_calendar).to eq([])
        expect(CalendarImporter::Parsers::Base).to have_received(:sleep).once
      end

      it "imports the events without descriptions once one description has used up its retries" do
        stub_request(:get, organiser_api).to_return(status: 200, body: "{}")
        stub_request(:get, events_page_url(1)).to_return(events_page(1, %w[1 2 3], page_count: 1))
        stub_request(:get, description_url("1")).to_return(description("<p>Full 1</p>"))
        stub_request(:get, description_url("2")).to_return(status: 500, body: "")
        stub_request(:get, description_url("3")).to_return(description("<p>Full 3</p>"))

        events = parser.download_calendar

        expect(events.map { it.dig("description", "html") }).to eq(["<p>Full 1</p>", "Short", "Short"])
        expect(a_request(:get, description_url("2"))).to have_been_made.times(max_retries + 1)
        expect(a_request(:get, description_url("3"))).not_to have_been_made
      end
    end
  end

  describe "#fetch_event_description" do
    it "returns nil when one event keeps failing" do
      stub_request(:get, description_url("123")).to_return(status: 500, body: "")

      expect(parser.fetch_event_description("123")).to be_nil
      expect(a_request(:get, description_url("123"))).to have_been_made.times(max_retries + 1)
    end

    it "returns nil when the connection keeps dropping" do
      stub_request(:get, description_url("123")).to_raise(Errno::ECONNRESET.new("Connection reset by peer - SSL_connect"))

      expect(parser.fetch_event_description("123")).to be_nil
      expect(a_request(:get, description_url("123"))).to have_been_made.times(max_retries + 1)
    end

    it "retries and returns the description once Eventbrite recovers" do
      stub_request(:get, description_url("123")).to_return({ status: 429, body: "" }, description("<p>recovered</p>"))

      expect(parser.fetch_event_description("123")).to eq("<p>recovered</p>")
      expect(CalendarImporter::Parsers::Base).to have_received(:sleep).once
    end

    it "stops fetching descriptions for the rest of the run after one fails" do
      stub_request(:get, description_url("1")).to_return(status: 500, body: "")
      stub_request(:get, description_url("2")).to_return(description("<p>2</p>"))

      expect(parser.fetch_event_description("1")).to be_nil
      expect(parser.fetch_event_description("2")).to be_nil
      expect(a_request(:get, description_url("2"))).not_to have_been_made
    end

    it "returns nil for an event whose description is gone, and keeps fetching the rest" do
      stub_request(:get, description_url("1")).to_return(status: 404, body: "{}")
      stub_request(:get, description_url("2")).to_return(description("<p>2</p>"))

      expect(parser.fetch_event_description("1")).to be_nil
      expect(parser.fetch_event_description("2")).to eq("<p>2</p>")
    end

    it "lets a timeout through" do
      stub_request(:get, description_url("1")).to_timeout

      expect { parser.fetch_event_description("1") }.to raise_error(Net::OpenTimeout)
    end
  end
end
