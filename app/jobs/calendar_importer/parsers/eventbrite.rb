# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Eventbrite < Base
    NAME = 'Eventbrite'
    KEY = 'eventbrite'
    DOMAINS = %w[www.eventbrite.com www.eventbrite.co.uk].freeze

    # Eventbrite is the only parser that talks to its API via RestClient (the
    # rest use HTTParty, whose transient responses are retried by status code in
    # Base.read_http_source / ApiBase). RestClient signals transient failures by
    # raising typed exceptions instead, so we hand Base.with_http_retries the
    # exception classes to retry. The SDK wraps RestClient::InternalServerError
    # as its own class for the list endpoint; 429/502/503/504 from the SDK
    # propagate as raw RestClient errors, and the description endpoint uses
    # RestClient directly. See AppSignal incidents #311/#331. This is the
    # exception-class mirror of Base::TRANSIENT_HTTP_STATUSES — keep the two in
    # sync when adding a transient case.
    TRANSIENT_HTTP_ERRORS = [
      EventbriteSDK::InternalServerError, # 500, wrapped by the SDK
      RestClient::InternalServerError,    # 500
      RestClient::BadGateway,             # 502
      RestClient::ServiceUnavailable,     # 503
      RestClient::GatewayTimeout,         # 504
      RestClient::TooManyRequests,        # 429 rate limit

      # Dropped-connection errors never get an HTTP status and RestClient lets
      # them propagate raw, so without these the retry loop and the graceful
      # degrade are both bypassed and the whole import crashes (AppSignal
      # incident #279, Errno::ECONNRESET during SSL_connect). All requests here
      # are GETs, so retrying is safe. Timeouts, SSL and DNS errors are
      # deliberately NOT listed: CalendarImporterJob's rescue_from backstop
      # already maps those to bad_source/unreachable (see issue #3100).
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::EPIPE
    ].freeze

    # Match Eventbrite organizer pages like:
    # https://www.eventbrite.co.uk/o/organiser-name-12345
    URL_PATTERNS = [
      { pattern: '^https://www\.eventbrite\.(com|co\.uk)/o/[A-Za-z0-9-]+', flags: '' }
    ].freeze

    def organizer_id
      path = URI.parse(@url).path
      path.split('/').last.split('-').last
    end

    def download_calendar
      EventbriteSDK.token = ENV.fetch('EVENTBRITE_TOKEN', nil)

      @events = []
      results = Base.with_http_retries('Eventbrite organiser events', retry_on: TRANSIENT_HTTP_ERRORS) do
        EventbriteSDK::Organizer.retrieve(id: organizer_id).events.with_expansion(:venue).page(1)
      end

      loop do
        results.map do |event|
          html = fetch_event_description(event.id)
          event.assign_attributes('description.html' => html) if html
        end
        @events += results
        results = Base.with_http_retries('Eventbrite next page', retry_on: TRANSIENT_HTTP_ERRORS) { results.next_page }
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
      # Circuit breaker: once a description fetch has exhausted its retries the
      # endpoint is likely down, so skip the rest for this run. Without this a
      # large calendar would pay (event count × backoff) seconds during an
      # outage and could exceed the worker's max_run_time — and the description
      # endpoint is exactly what fails in incidents #311/#200.
      return if @skip_descriptions

      Base.with_http_retries("Eventbrite event #{event_id} description", retry_on: TRANSIENT_HTTP_ERRORS) do
        get_event_description(EventbriteSDK.token, event_id)
      end
    rescue *TRANSIENT_HTTP_ERRORS => e
      @skip_descriptions = true
      Rails.logger.warn(
        "Eventbrite description fetch failed for event #{event_id} (#{e.class}: #{e.message}); " \
        'skipping descriptions for the rest of this import'
      )
      nil
    end

    # Get full event description
    def get_event_description(token, event_id)
      resource = RestClient::Resource.new("https://www.eventbriteapi.com/v3/events/#{event_id}/description/")
      response = resource.get(:Authorization => "Bearer #{token}")
      Base.safely_parse_json(response)['description']
    end
  end
end
