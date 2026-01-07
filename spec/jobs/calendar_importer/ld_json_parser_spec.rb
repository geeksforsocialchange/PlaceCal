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

      parser = described_class.new(calendar, url: url)

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
end
