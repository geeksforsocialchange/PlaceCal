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
        results.map do |event|
          html = get_event_description(EventbriteSDK.token, event.id)
          event.assign_attributes('description.html' => html)
        end
        @events += results
        results = results.next_page
        break if results.blank?
      end

      @events
    rescue RestClient::BadGateway => e
      []
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::EventbriteEvent.new(d) }
    end

    # Get full event description
    def get_event_description(token, event_id)
      resource = RestClient::Resource.new("https://www.eventbriteapi.com/v3/events/#{event_id}/description/")
      response = resource.get(:Authorization => "Bearer #{token}")
      Base.safely_parse_json(response)['description']
    end
  end
end
