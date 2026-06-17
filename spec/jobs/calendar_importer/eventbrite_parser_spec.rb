# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarImporter::Parsers::Eventbrite do
  describe "#download_calendar" do
    it "extracts events from Eventbrite calendars" do
      os_event_url = "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483"

      VCR.use_cassette(:eventbrite_events) do
        calendar = create(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: os_event_url
        )
        expect(calendar).to be_valid

        parser = described_class.new(calendar, url: os_event_url)

        # we are only checking for RDF records extracted from response
        records = parser.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(72)
      end
    end

    it "ignores 504 bad gateway responses" do
      os_event_url = "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483"

      VCR.use_cassette(:eventbrite_bad_gateway) do
        calendar = build(
          :calendar,
          strategy: :event,
          name: :import_test_calendar,
          source: os_event_url
        )
        expect(calendar).to be_valid

        parser = described_class.new(calendar, url: os_event_url)

        # This validates that download_calendar does NOT raise BadGateway
        # There was a bug in how RestClient reports the BadGateway exception
        expect { parser.download_calendar }.not_to raise_error
      end
    end

    context "when Eventbrite's API returns transient errors (5xx / 429)" do
      let(:os_event_url) { "https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483" }
      let(:calendar) do
        build(:calendar, strategy: :event, name: :import_test_calendar, source: os_event_url)
          .tap { |c| allow(c).to receive(:check_source_reachable) }
      end
      let(:parser) { described_class.new(calendar, url: os_event_url) }

      before { allow(parser).to receive(:sleep) } # don't actually back off in tests

      it "retries the organiser listing and degrades to an empty result when it keeps failing" do
        allow(EventbriteSDK::Organizer).to receive(:retrieve)
          .and_raise(EventbriteSDK::InternalServerError.new("internal server error"))

        # An ongoing Eventbrite outage must not crash the import (which would
        # flag the calendar as errored and wipe nothing) — it returns [].
        expect(parser.download_calendar).to eq([])
        expect(parser).to have_received(:sleep).exactly(described_class::MAX_RETRIES).times
        expect(EventbriteSDK::Organizer).to have_received(:retrieve)
          .exactly(described_class::MAX_RETRIES + 1).times
      end

      it "treats a raw 429 from the listing endpoint as transient too" do
        allow(EventbriteSDK::Organizer).to receive(:retrieve)
          .and_raise(RestClient::TooManyRequests)

        expect(parser.download_calendar).to eq([])
        expect(EventbriteSDK::Organizer).to have_received(:retrieve)
          .exactly(described_class::MAX_RETRIES + 1).times
      end

      it "does not retry or swallow non-transient errors" do
        allow(EventbriteSDK::Organizer).to receive(:retrieve)
          .and_raise(RestClient::Unauthorized)

        expect { parser.download_calendar }.to raise_error(RestClient::Unauthorized)
        expect(parser).not_to have_received(:sleep)
      end

      describe "#fetch_event_description" do
        it "skips the description (returns nil) when one event keeps failing" do
          allow(parser).to receive(:get_event_description).and_raise(RestClient::InternalServerError)

          expect(parser.fetch_event_description("123")).to be_nil
          expect(parser).to have_received(:get_event_description)
            .exactly(described_class::MAX_RETRIES + 1).times
        end

        it "retries and returns the description once Eventbrite recovers" do
          call_count = 0
          allow(parser).to receive(:get_event_description) do
            call_count += 1
            raise RestClient::TooManyRequests if call_count < 2

            "<p>recovered</p>"
          end

          expect(parser.fetch_event_description("123")).to eq("<p>recovered</p>")
          expect(call_count).to eq(2)
        end
      end
    end

    it "raises InaccessibleFeed when the Eventbrite organiser no longer exists" do
      os_event_url = "https://www.eventbrite.co.uk/o/deleted-organiser-99999999999"
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: os_event_url
      )
      allow(calendar).to receive(:check_source_reachable)

      parser = described_class.new(calendar, url: os_event_url)
      allow(EventbriteSDK::Organizer).to receive(:retrieve).and_raise(EventbriteSDK::ResourceNotFound)

      # A deleted/renamed organiser must surface as an unreachable source
      # (-> bad_source) rather than an uncaught exception that strands the
      # calendar in `in_worker` and retries forever.
      expect { parser.download_calendar }
        .to raise_error(CalendarImporter::Exceptions::InaccessibleFeed, /not found/)
    end
  end
end
