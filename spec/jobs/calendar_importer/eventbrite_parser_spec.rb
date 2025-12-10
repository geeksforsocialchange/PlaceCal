# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarImporter::Parsers::Eventbrite do
  describe '#download_calendar' do
    it 'extracts events from Eventbrite calendars' do
      os_event_url = 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483'

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

    it 'ignores 504 bad gateway responses' do
      os_event_url = 'https://www.eventbrite.co.uk/o/queer-lit-social-refuge-48062165483'

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
  end
end
