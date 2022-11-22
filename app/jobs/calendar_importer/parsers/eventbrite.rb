# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Eventbrite < Base
    NAME = 'Eventbrite'
    KEY = 'eventbrite'
    DOMAINS = %w[www.eventbrite.com www.eventbrite.co.uk].freeze

    def self.allowlist_pattern
      %r{^https://www.eventbrite\.(com|co.uk)/o/[A-Za-z0-9-]+}
    end

    def organizer_id
      path = URI.parse(@url).path
      path.split('/').last.split('-').last
    end

    def download_calendar
      EventbriteSDK.token = ENV.fetch('EVENTBRITE_TOKEN', nil)

      @events = []
      results = EventbriteSDK::Organizer.retrieve(id: organizer_id).events.with_expansion(:venue).page(1)

      loop do
        @events += results
        results = results.next_page
        break if results.blank?
      end

      @events
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::EventbriteEvent.new(d) }
    end
  end
end
