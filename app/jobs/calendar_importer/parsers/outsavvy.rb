# frozen_string_literal: true

module CalendarImporter::Parsers
  class Outsavvy < Base
    NAME = 'OutSavvy'
    KEY = 'outsavvy'
    DOMAINS = %w[outsavvy.com].freeze

    # Custom EventConsumer that uses OutsavvyEvent to handle malformed timestamps
    class EventConsumer < LdJson::EventConsumer
      def consume_event(data)
        events << ::CalendarImporter::Events::OutsavvyEvent.new(data)
      end
    end

    def self.allowlist_pattern
      %r{^https://www\.outsavvy\.com/organiser/[^/]*/?$}
    end

    # Get event URLs from an organiser page

    def extract_event_urls(organiser_url)
      response_body = Base.read_http_source(organiser_url)

      doc = Nokogiri::HTML(response_body)

      live_events = doc.xpath('//div[@id="live_events"]/div[@id="eventscontent"]/div/*')

      live_events.map { |event| event.xpath('./div/a').attr('href').value }
    end

    def download_calendar
      extract_event_urls(@url).flat_map do |event_url|
        Base.parse_ld_json(event_url)
      end
    end

    def import_events_from(data)
      consumer = EventConsumer.new
      consumer.consume data
      consumer.validate_events
      consumer.events
    end
  end
end
