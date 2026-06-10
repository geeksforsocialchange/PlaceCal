# frozen_string_literal: true

# Ported from PlaceCal spec/jobs/calendar_importer/eventbrite_parser_spec.rb.
# The Eventbrite reader now takes its API token from source.token instead of
# ENV['EVENTBRITE_TOKEN'] (nil is fine for VCR playback).

RSpec.describe PanCal::Readers::Eventbrite do
  describe '#download_calendar' do
    it 'extracts events from Eventbrite calendars' do
      os_event_url = 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483'

      VCR.use_cassette(:eventbrite_events) do
        source = PanCal::Source.new(url: os_event_url)

        reader = described_class.new(source)

        # we are only checking for RDF records extracted from response
        records = reader.download_calendar
        expect(records).to be_a(Array)
        expect(records.count).to eq(72)
      end
    end

    it 'ignores 504 bad gateway responses' do
      os_event_url = 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483'

      VCR.use_cassette(:eventbrite_bad_gateway) do
        source = PanCal::Source.new(url: os_event_url)

        reader = described_class.new(source)

        # This validates that download_calendar does NOT raise BadGateway
        # There was a bug in how RestClient reports the BadGateway exception
        expect { reader.download_calendar }.not_to raise_error
      end
    end

    it 'raises InaccessibleFeed when the Eventbrite organiser no longer exists' do
      os_event_url = 'https://www.eventbrite.co.uk/o/deleted-organiser-99999999999'
      source = PanCal::Source.new(url: os_event_url)

      reader = described_class.new(source)
      allow(EventbriteSDK::Organizer).to receive(:retrieve).and_raise(EventbriteSDK::ResourceNotFound)

      # A deleted/renamed organiser must surface as an unreachable source
      # (-> bad_source) rather than an uncaught exception that strands the
      # calendar in `in_worker` and retries forever.
      expect { reader.download_calendar }
        .to raise_error(PanCal::InaccessibleFeed, /not found/) do |error|
          expect(error.code).to eq(:not_found)
        end
    end
  end
end
