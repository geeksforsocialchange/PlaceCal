# frozen_string_literal: true

require 'test_helper'

class LdJsonParserTest < ActiveSupport::TestCase
  def check_source_has_events(url, cassette, expected_node_count, expected_event_count)
    VCR.use_cassette(cassette, allow_playback_repeats: true) do
      calendar = create(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: url
      )
      assert_predicate calendar, :valid?

      parser = CalendarImporter::Parsers::LdJson.new(calendar, url: url)

      # we are only checking for RDF records extracted from response
      records = parser.download_calendar
      assert_kind_of Array, records
      assert_equal expected_node_count, records.count, "Expected #{expected_node_count} nodes but found #{records.count}"

      events = parser.import_events_from(records)
      assert_equal expected_event_count, events.count, "Expected #{expected_event_count} events but found #{events.count}"
    end
  end

  test 'extracts events from DiceFM calendars' do
    check_source_has_events 'https://dice.fm/venue/folklore-2or7', :dice_fm_events, 3, 15
  end

  test 'extracts events from OutSavvy calendars' do
    check_source_has_events 'https://www.outsavvy.com/organiser/sappho-events', :out_savvy_events, 3, 4
  end

  test 'extracts events from LD+JSON calendar sources' do
    # maybe look into why PXSSY PALACE isn't being picked up
    # check_source_has_events 'https://www.pxssypalace.com/schedule', :pxspalace_events, 3, 1

    check_source_has_events 'https://www.heartoftorbaycic.com/events/', :heart_of_torbay_events, 2, 1
  end
end
