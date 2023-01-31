# frozen_string_literal: true

require 'test_helper'

class MeetupParserTest < ActiveSupport::TestCase
  test 'downloads and parses data correctly' do
    meetup_url = 'https://www.meetup.com/tglondon/'

    VCR.use_cassette(:good_meetup_source) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: meetup_url
      )

      parser = CalendarImporter::Parsers::Meetup.new(calendar, url: meetup_url)

      data = parser.download_calendar
      assert_equal 134, data.length
    end
  end

  test 'handles badly formed responses (non JSON)' do
    # non existant user
    bad_user_url = 'https://www.meetup.com/haeKohtheuwae7uY6sie'

    VCR.use_cassette(:bad_meetup_gateway) do
      # FIXME: this is cheating a bit as we are knowingly building an
      #  invalid calendar that would never exist IRL. but we get around
      #  this by not saving it.

      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: bad_user_url
      )
      # assert_predicate calendar, :valid?

      parser = CalendarImporter::Parsers::Meetup.new(calendar, url: bad_user_url)

      error = assert_raises(CalendarImporter::Exceptions::InaccessibleFeed) do
        parser.download_calendar # raises InaccessibleFeed
      end
    end
  end
end
