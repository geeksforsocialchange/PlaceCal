# frozen_string_literal: true

require 'test_helper'

class EventbriteParserTest < ActiveSupport::TestCase
  test 'extracts events from Eventbrite calendars' do
    os_event_url = 'https://www.eventbrite.co.uk/o/ftm-london-32888898939'

    VCR.use_cassette(:eventbrite_events) do
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: os_event_url
      )
      assert_predicate calendar, :valid?

      parser = CalendarImporter::Parsers::Eventbrite.new(calendar, url: os_event_url)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      assert_kind_of(Array, records)
      assert_equal 17, records.count
    end
  end

  test 'ignores 504 bad gateway responses' do
    os_event_url = 'https://www.eventbrite.co.uk/o/ftm-london-32888898939'

    VCR.use_cassette(:eventbrite_bad_gateway) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: os_event_url
      )

      parser = CalendarImporter::Parsers::Eventbrite.new(calendar, url: os_event_url)

      begin
        records = parser.download_calendar
      rescue RestClient::BadGateway
        # this is essentially validating that the download_calendar
        #    method is NOT raising a BadGateway exception.
        #    There is a bug in how RestClient reports the BadGateway
        #    exception is raised that itself was causing an exception.
        flunk 'Was not expecting RestClient::BadGateway'
      end
    end
  end
end
