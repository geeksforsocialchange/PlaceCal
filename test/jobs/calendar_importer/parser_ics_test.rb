# frozen_string_literal: true

require 'test_helper'

class ParserIcsTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def setup
    blank_calendar = Calendar.new
    @base = CalendarImporter::Parsers::Ics.new(blank_calendar)
  end

  test 'parse_remote_calendars parses ICS' do
    ics_data = fixture_file_upload('family-action-org-uk.ics')
    events = @base.parse_remote_calendars(ics_data)
    assert_equal 1, events.length
  end

  test 'parse_remote_calendars handles missing ICAL data' do
    error = assert_raises(CalendarImporter::Exceptions::BadFeedResponse) do
      @base.parse_remote_calendars ''
    end

    assert_equal 'Source returned empty ICS data', error.message
  end

  test 'parse_remote_calendars handles badly formed ICAL data' do
    bad_ics_path = File.join(fixture_path, 'files/family-action-org-uk-bad.ics')
    bad_ics_data = File.read(bad_ics_path)

    error = assert_raises(CalendarImporter::Exceptions::BadFeedResponse) do
      @base.parse_remote_calendars bad_ics_data
    end

    assert_equal 'Could not parse ICS response (Invalid iCalendar input line: */)', error.message
  end
end
