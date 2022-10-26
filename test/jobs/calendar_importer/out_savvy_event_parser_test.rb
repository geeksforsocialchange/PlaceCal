# frozen_string_literal: true

require 'test_helper'

class OutSavvyParserTest < ActiveSupport::TestCase
  test 'extracts events from OpenSavvy calendars' do
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

      events = parser.download_calendar
      assert events.is_a?(Array)
    end
  end
end
