# frozen_string_literal: true

require 'test_helper'

class OutsavvyParserTest < ActiveSupport::TestCase
  test 'extracts event URLs from organiser page with live events' do
    outsavvy_url = 'https://www.outsavvy.com/organiser/a-whole-orange'
    url_pattern = %r{^https://www\.outsavvy\.com/event/[A-Za-z0-9-]+}

    VCR.use_cassette(:outsavvy_events) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: outsavvy_url
      )

      parser = CalendarImporter::Parsers::Outsavvy.new(calendar, url: outsavvy_url)

      data = parser.extract_event_urls(outsavvy_url)

      data.map do |url|
        assert_match(url_pattern, url)
      end
    end
  end

  test 'returns empty list for organiser page with no events' do
    outsavvy_url = 'https://www.outsavvy.com/organiser/treacles'

    VCR.use_cassette(:outsavvy_no_events) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: outsavvy_url
      )

      parser = CalendarImporter::Parsers::Outsavvy.new(calendar, url: outsavvy_url)

      data = parser.extract_event_urls(outsavvy_url)

      assert_empty(data)
    end
  end

  test 'gets URL of original event listing' do
    VCR.use_cassette(:outsavvy_publisher_url) do
      calendar = build(
        :calendar,
        strategy: :event,
        name: :import_test_calendar,
        source: 'https://www.outsavvy.com/organiser/ldn-queer-mart'
      )

      parser = CalendarImporter::Parsers::Outsavvy.new(calendar, url: calendar.source)

      data = parser.download_calendar

      consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
      consumer.consume data
      consumer.validate_events
      consumer.events

      expected = 'https://www.outsavvy.com/event/25977/ldn-queer-mart-lgbtqia-art-market'

      assert_equal(consumer.events[0].publisher_url, expected)
    end
  end
end
