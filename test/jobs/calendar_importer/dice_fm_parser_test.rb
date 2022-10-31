# frozen_string_literal: true

require 'test_helper'

class DiceFmParserTest < ActiveSupport::TestCase
  test 'extracts events from DiceFM calendars' do
    os_event_url = 'https://dice.fm/venue/folklore-2or7'

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: os_event_url
    )
    assert_predicate calendar, :valid?

    VCR.use_cassette(:dice_fm_events) do
      parser = CalendarImporter::Parsers::DiceFm.new(calendar, url: os_event_url)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      assert records.is_a?(Array)
      assert_equal 3, records.count
    end
  end
end
