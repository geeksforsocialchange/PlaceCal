# frozen_string_literal: true

require 'test_helper'

class OutSavvyParserTest < ActiveSupport::TestCase
  test 'extracts events from OutSavvy calendars' do
    os_event_url = 'https://www.outsavvy.com/organiser/sappho-events'

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: os_event_url
    )
    assert_predicate calendar, :valid?

    VCR.use_cassette(:out_savvy_events) do
      parser = CalendarImporter::Parsers::OutSavvy.new(calendar, url: os_event_url)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      assert records.is_a?(Array)
      assert_equal 6, records.count
    end
  end
end
