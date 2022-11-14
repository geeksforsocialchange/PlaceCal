# frozen_string_literal: true

require 'test_helper'

class EventbriteParserTest < ActiveSupport::TestCase
  test 'extracts events from Eventbrite calendars' do
    os_event_url = 'https://www.eventbrite.co.uk/o/ftm-london-32888898939'

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: os_event_url
    )
    assert_predicate calendar, :valid?

    VCR.use_cassette(:eventbrite_events) do
      parser = CalendarImporter::Parsers::Eventbrite.new(calendar, url: os_event_url)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      assert records.is_a?(Array)
      assert_equal 17, records.count
    end
  end
end
