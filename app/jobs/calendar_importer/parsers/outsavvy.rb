# frozen_string_literal: true

module CalendarImporter::Parsers
  class Outsavvy < Base
    NAME = 'OutSavvy'
    KEY = 'outsavvy'
    DOMAINS = %w[outsavvy.com].freeze

    def self.allowlist_pattern
      %r{^https://www\.outsavvy\.com/[^/]*/?$}
    end

    # Fetch a list of event-specific URLs from an organiser page

    def extract_event_urls
      response_body = Base.read_http_source(@url)

      doc = Nokogiri::HTML(response_body)

      live_events = doc.xpath('//div[@id="live_events"]/div[@id="eventscontent"]/div/*')

      urls = live_events.map do |event|
        event.xpath('./div/a').attr('href').value
      end
    end

    def download_calendar
      urls = extract_event_urls
      # Pass each URL to the linked_data_event importer
    end

    def import_events_from(data); end
  end
end
