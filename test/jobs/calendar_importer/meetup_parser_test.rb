# frozen_string_literal: true

require 'test_helper'

class MeetupParserTest < ActiveSupport::TestCase
  test 'handles badly formed responses (non JSON)' do

    # non existant user
    bad_user_url = 'https://www.meetup.com/haeKohtheuwae7uY6sie' 

    calendar = create(
      :calendar,
      strategy: :event,
      name: :import_test_calendar,
      source: bad_user_url
    )
    assert calendar.valid?

    VCR.use_cassette(:bad_meetup_gateway) do
      parser = CalendarImporter::Parsers::Meetup.new(calendar, url: bad_user_url)

      events = parser.download_calendar
      assert_equal events, [], 'expected empty array'
    end
  end
end