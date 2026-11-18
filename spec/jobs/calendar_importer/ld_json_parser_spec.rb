# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::LdJson do
  def check_source_has_events(url, cassette, expected_node_count, expected_event_count)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: url
      )
      expect(calendar).to be_valid

      parser = described_class.new(calendar, url:)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      expect(records).to be_a(Array)
      expect(records.count).to eq(expected_node_count)

      events = parser.import_events_from(records)
      expect(events.count).to eq(expected_event_count)
    end
  end

  describe "#download_calendar" do
    it "extracts events from DiceFM calendars" do
      check_source_has_events "https://dice.fm/venue/folklore-2or7", :dice_fm_events, 3, 15
    end

    it "extracts events from OutSavvy calendars" do
      check_source_has_events "https://www.outsavvy.com/organiser/sappho-events", :out_savvy_events, 3, 4
    end

    it "extracts events from LD+JSON calendar sources" do
      check_source_has_events "https://www.heartoftorbaycic.com/events/", :heart_of_torbay_events, 2, 1
    end
  end

  describe "event status" do
    let(:url) { "https://example.com/events" }
    let(:calendar) { build(:calendar, strategy: :event, source: url) }

    def ld_json_event(name, status = nil)
      event = {
        "@type" => "Event",
        "name" => name,
        "url" => "https://example.com/events/#{name.parameterize}",
        "startDate" => "2030-01-01T19:00:00+00:00"
      }
      event["eventStatus"] = status if status
      event
    end

    def stub_page(*events)
      json = { "@context" => "https://schema.org", "@graph" => events }.to_json
      stub_request(:get, url).to_return(
        status: 200,
        body: "<html><head><script type=\"application/ld+json\">#{json}</script></head></html>"
      )
    end

    def imported_names
      parser = described_class.new(calendar)
      parser.import_events_from(parser.download_calendar).map(&:summary)
    end

    def imported_statuses
      parser = described_class.new(calendar)
      parser.import_events_from(parser.download_calendar).to_h { [it.summary, it.status] }
    end

    it "imports events with no eventStatus" do
      stub_page ld_json_event("No status")

      expect(imported_names).to eq(["No status"])
    end

    it "imports scheduled, rescheduled and moved online events" do
      stub_page ld_json_event("Scheduled", "https://schema.org/EventScheduled"),
                ld_json_event("Rescheduled", "http://schema.org/EventRescheduled"),
                ld_json_event("Moved online", "EventMovedOnline")

      expect(imported_names).to contain_exactly("Scheduled", "Rescheduled", "Moved online")
    end

    it "marks cancelled events however the status is written, keeping them" do
      stub_page ld_json_event("Cancelled https", "https://schema.org/EventCancelled"),
                ld_json_event("Cancelled http", "http://schema.org/EventCancelled"),
                ld_json_event("Cancelled bare", "EventCancelled"),
                ld_json_event("Cancelled prefixed", "schema:EventCancelled"),
                ld_json_event("Cancelled id", { "@id" => "https://schema.org/EventCancelled" }),
                ld_json_event("Kept")

      expect(imported_statuses).to eq("Cancelled https" => "cancelled", "Cancelled http" => "cancelled", "Cancelled bare" => "cancelled",
                                      "Cancelled prefixed" => "cancelled", "Cancelled id" => "cancelled", "Kept" => "scheduled")
    end

    it "marks postponed events, keeping them on their old date" do
      stub_page ld_json_event("Postponed", "https://schema.org/EventPostponed"), ld_json_event("Rescheduled", "EventRescheduled")

      expect(imported_statuses).to eq("Postponed" => "postponed", "Rescheduled" => "scheduled")
    end

    describe ".handles_url?" do
      it "accepts a page whose events have no eventStatus" do
        stub_page ld_json_event("No status"), ld_json_event("Also no status")

        expect(described_class.handles_url?(calendar)).to be(true)
      end

      it "accepts a page whose only events are cancelled, since they're still listed" do
        stub_page ld_json_event("Cancelled", "http://schema.org/EventCancelled")

        expect(described_class.handles_url?(calendar)).to be(true)
      end
    end
  end
end
