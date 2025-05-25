# frozen_string_literal: true

require 'test_helper'

class OutsavvyParserTest < ActiveSupport::TestCase
  test 'extracts event URLs from organiser page' do
    outsavvy_url = 'https://www.outsavvy.com/organiser/a-whole-orange'

    VCR.use_cassette(:outsavvy_events) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: outsavvy_url
      )

      parser = CalendarImporter::Parsers::Outsavvy.new(calendar, url: outsavvy_url)

      data = parser.extract_event_urls
      assert_equal 6, data.length
    end
  end
end
