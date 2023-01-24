# frozen_string_literal: true

require 'test_helper'

class EventParseIcsTest < ActiveSupport::TestCase
  test 'Parsing bad ICS data is caught and signalled' do
    bad_calendar_url = 'https://calendar.google.com/calendar/u/0/r?tab=rc&pli=1'

    VCR.use_cassette('Importer ICS Bad Response', allow_playback_repeats: true) do
      calendar = create(:calendar, source: bad_calendar_url)
      args = {
        url: bad_calendar_url,
        from: Time.zone.today
      }

      parser = CalendarImporter::Parsers::Ics.new(calendar, args)

      assert_raises CalendarImporter::Exceptions::BadFeedResponse do
        parser.calendar_to_events
      end
    end
  end
end
