# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to CalendarImporter::CalendarImporter::PARSERS.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Eventbrite < Base
    NAME = 'Eventbrite'
    HANDBOOK_PAGE = 'eventbrite'
    TIER = :silver
    TICKETING = true
    KEY = 'eventbrite'
    DOMAINS = %w[www.eventbrite.com www.eventbrite.co.uk].freeze
    API_BASE_URL = 'https://www.eventbriteapi.com/v3'

    # A dropped connection has no status to retry on, so these are retried by class
    DROPPED_CONNECTION_ERRORS = [Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EPIPE].freeze

    # Eventbrite kept answering with a transient status after every retry
    class TransientFailure < StandardError; end

    # Eventbrite answered with a status the importer can't act on, such as a rejected token
    class ApiError < StandardError; end

    def self.event_class = CalendarImporter::Events::EventbriteEvent

    def self.allowlist_pattern
      %r{^https://www\.eventbrite\.(com|co\.uk)/o/[A-Za-z0-9-]+}
    end

    def organizer_id
      path = URI.parse(@url).path
      path.split('/').last.split('-').last
    end

    def download_calendar
      # The organiser's own record is what answers 404 once it is deleted or renamed
      get_json("organizers/#{organizer_id}/", 'Eventbrite organiser')
      events = fetch_events
      events.each { |event| add_description(event) }
      events
    rescue TransientFailure, *DROPPED_CONNECTION_ERRORS => e
      # An empty list would read as a feed with no events and start its removal countdown
      Rails.logger.warn("Eventbrite import skipped for #{@url}: #{e.class} (#{e.message})")
      raise SourceUnavailable, "#{e.class}: #{e.message}"
    rescue ApiNotFound
      raise InaccessibleFeed, "Eventbrite organiser #{organizer_id} not found (requested object was not found)"
    end

    def import_events_from(data)
      data.map { |d| self.class.event_class.new(d) }
    end

    # @return [String, nil] the event's full description, or nil when it can't be fetched
    def fetch_event_description(event_id)
      # Once one fetch has used up its retries the endpoint is likely down, so the rest are skipped
      return if @skip_descriptions

      json = get_json("events/#{event_id}/description/", "Eventbrite event #{event_id} description")
      raise InvalidResponse, 'Eventbrite responded with an unexpected description' unless json.is_a?(Hash)

      json['description']
    rescue TransientFailure, *DROPPED_CONNECTION_ERRORS => e
      @skip_descriptions = true
      Rails.logger.warn(
        "Eventbrite description fetch failed for event #{event_id} (#{e.class}: #{e.message}); " \
        'skipping descriptions for the rest of this import'
      )
      nil
    rescue ApiNotFound
      Rails.logger.warn("Eventbrite description not found for event #{event_id}")
      nil
    end

    private

    # A short list is worse than none: the import deletes every upcoming event missing from it
    def fetch_events
      events = []
      page = 1
      first = last = nil
      loop do
        json = get_json("organizers/#{organizer_id}/events/?expand=venue&page=#{page}", "Eventbrite organiser events page #{page}")
        raise InvalidResponse, 'Eventbrite responded without an events list' unless events_page?(json)

        last = json['pagination']
        first ||= last
        raise InvalidResponse, 'Eventbrite changed the page count mid-list' if last['page_count'] != first['page_count']

        events.concat(json['events'])
        break if page >= last['page_count']

        page += 1
      end
      check_complete!(events, first, last)
      events
    end

    def check_complete!(events, first, last)
      raise InvalidResponse, 'Eventbrite reported more events after the last page' if last['has_more_items'] == true

      total = first['object_count']
      raise InvalidResponse, "Eventbrite listed #{events.size} of #{total} events" if total.is_a?(Integer) && events.size < total
    end

    def events_page?(json)
      json.is_a?(Hash) && json['events'].is_a?(Array) &&
        json['pagination'].is_a?(Hash) && json['pagination']['page_count'].is_a?(Integer)
    end

    def add_description(event)
      html = fetch_event_description(event['id'])
      event['description'] = (event['description'] || {}).merge('html' => html) if html
    end

    def get_json(path, context)
      response = Base.with_http_retries(
        context,
        retry_on: DROPPED_CONNECTION_ERRORS,
        retry_if: ->(r) { TRANSIENT_HTTP_STATUSES.include?(r.code) }
      ) do
        # Not following redirects keeps the token from being sent to another host
        HTTParty.get("#{API_BASE_URL}/#{path}", headers: request_headers, follow_redirects: false)
      end

      raise TransientFailure, "#{context}: HTTP #{response.code}" if TRANSIENT_HTTP_STATUSES.include?(response.code)
      raise ApiNotFound, "#{context}: HTTP 404" if response.code == 404
      raise ApiError, "#{context}: HTTP #{response.code}" unless response.success?

      Base.safely_parse_json(response.body)
    end

    def request_headers
      token = ENV.fetch('EVENTBRITE_TOKEN', nil)
      headers = { 'Accept' => 'application/json' }
      headers['Authorization'] = "Bearer #{token}" if token.present?
      headers
    end
  end
end
