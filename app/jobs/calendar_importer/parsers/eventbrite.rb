# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Eventbrite < Base
    NAME = 'Eventbrite'
    KEY = 'eventbrite'
    DOMAINS = %w[www.eventbrite.com www.eventbrite.co.uk].freeze

    # Eventbrite's API intermittently returns 5xx and 429 responses (see
    # AppSignal incidents #311/#331). These are transient upstream failures, not
    # problems with our request, so retry with backoff before giving up.
    # The SDK wraps RestClient::InternalServerError as its own class for the
    # list endpoint; 429/502/503/504 from the SDK propagate as raw RestClient
    # errors, and the description endpoint uses RestClient directly.
    TRANSIENT_HTTP_ERRORS = [
      EventbriteSDK::InternalServerError, # 500, wrapped by the SDK
      RestClient::InternalServerError,    # 500
      RestClient::BadGateway,             # 502
      RestClient::ServiceUnavailable,     # 503
      RestClient::GatewayTimeout,         # 504
      RestClient::TooManyRequests         # 429 rate limit
    ].freeze

    MAX_RETRIES = 3
    RETRY_BACKOFF = 2 # seconds, multiplied by the attempt number

    def self.allowlist_pattern
      %r{^https://www\.eventbrite\.(com|co\.uk)/o/[A-Za-z0-9-]+}
    end

    def organizer_id
      path = URI.parse(@url).path
      path.split('/').last.split('-').last
    end

    def download_calendar
      EventbriteSDK.token = ENV.fetch('EVENTBRITE_TOKEN', nil)

      @events = []
      results = with_retries('organiser events') do
        EventbriteSDK::Organizer.retrieve(id: organizer_id).events.with_expansion(:venue).page(1)
      end

      loop do
        results.map do |event|
          html = fetch_event_description(event.id)
          event.assign_attributes('description.html' => html) if html
        end
        @events += results
        results = with_retries('next page') { results.next_page }
        break if results.blank?
      end

      @events
    rescue *TRANSIENT_HTTP_ERRORS => e
      # Retries exhausted. Eventbrite is having a transient outage; skip this
      # run rather than crashing the import (which flags the calendar into the
      # terminal `error` state and floods error tracking). Returning [] leaves
      # the calendar's existing events untouched — the importer only purges
      # stale events when it gets a non-empty result (see CalendarImporterTask).
      Rails.logger.warn("Eventbrite import skipped for #{@url}: #{e.class} (#{e.message})")
      []
    rescue EventbriteSDK::ResourceNotFound => e
      # The Eventbrite organiser no longer exists — usually deleted, or renamed
      # (which changes the numeric id baked into the source URL). Flag the
      # calendar as a bad source rather than letting the error bubble up
      # unhandled, which would strand the calendar in `in_worker` and retry the
      # dead organiser forever.
      raise InaccessibleFeed, "Eventbrite organiser #{organizer_id} not found (#{e.message})"
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::EventbriteEvent.new(d) }
    end

    # Fetch a single event's full description, tolerating transient Eventbrite
    # failures. The description is supplementary, so a failed fetch for one
    # event must not lose the whole calendar — import the event without it.
    def fetch_event_description(event_id)
      with_retries("event #{event_id} description") do
        get_event_description(EventbriteSDK.token, event_id)
      end
    rescue *TRANSIENT_HTTP_ERRORS => e
      Rails.logger.warn(
        "Eventbrite description fetch failed for event #{event_id}: #{e.class} (#{e.message})"
      )
      nil
    end

    # Get full event description
    def get_event_description(token, event_id)
      resource = RestClient::Resource.new("https://www.eventbriteapi.com/v3/events/#{event_id}/description/")
      response = resource.get(:Authorization => "Bearer #{token}")
      Base.safely_parse_json(response)['description']
    end

    private

    # Run the block, retrying on transient Eventbrite HTTP failures (5xx/429)
    # with a linear backoff. Re-raises the last error once retries are
    # exhausted so the caller can decide how to degrade.
    def with_retries(context)
      attempt = 0
      begin
        yield
      rescue *TRANSIENT_HTTP_ERRORS => e
        attempt += 1
        raise if attempt > MAX_RETRIES

        Rails.logger.warn(
          "Eventbrite #{context} transient error (#{e.class}: #{e.message}), " \
          "retry #{attempt}/#{MAX_RETRIES}"
        )
        sleep(RETRY_BACKOFF * attempt)
        retry
      end
    end
  end
end
