# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.
# Parent parser classes should not be added.
#
# This is the first parser that uses an authenticated REST API rather than
# scraping HTML or parsing iCal feeds. If we add a second API-based importer,
# consider extracting shared auth/pagination logic into a base class.

module CalendarImporter
  module Parsers
    class Tickettailor < Base
      NAME = 'Ticket Tailor'
      KEY = 'tickettailor'
      DOMAINS = %w[www.tickettailor.com tickettailor.com].freeze

      API_BASE_URL = 'https://api.tickettailor.com/v1'

      # Match TicketTailor box office pages like:
      # https://www.tickettailor.com/events/queerrunclub
      # https://tickettailor.com/events/some-org
      def self.allowlist_pattern
        %r{^https://(www\.)?tickettailor\.com/events/[^/]+/?$}i
      end

      def download_calendar
        validate_api_key!
        fetch_all_events
      end

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.filter_map do |event_data|
          # Only import published events
          next unless event_data['status'] == 'published'

          Events::TickettailorEvent.new(event_data)
        end
      end

      private

      def api_key
        @calendar.api_token
      end

      def validate_api_key!
        return if api_key.present?

        raise InaccessibleFeed,
              'TicketTailor API key required. Please add your API key to the calendar settings.'
      end

      def fetch_all_events
        events = []
        starting_after = nil

        loop do
          response = fetch_events_page(starting_after)
          page_events = response['data'] || []

          break if page_events.empty?

          events.concat(page_events)

          # Check for more pages
          next_link = response.dig('links', 'next')
          break unless next_link

          # Extract cursor from next link
          starting_after = page_events.last&.dig('id')
          break unless starting_after
        end

        events
      end

      def fetch_events_page(starting_after = nil)
        url = build_events_url(starting_after)
        response = make_api_request(url)
        Base.safely_parse_json(response)
      end

      def build_events_url(starting_after = nil)
        params = {
          status: 'published',
          limit: 100
        }
        params[:starting_after] = starting_after if starting_after

        query_string = params.map { |k, v| "#{k}=#{v}" }.join('&')
        "#{API_BASE_URL}/events?#{query_string}"
      end

      def make_api_request(url)
        # TicketTailor uses HTTP Basic Auth with the API key as username
        encoded_key = Base64.strict_encode64("#{api_key}:")

        response = HTTParty.get(
          url,
          headers: {
            'Accept' => 'application/json',
            'Authorization' => "Basic #{encoded_key}"
          }
        )

        unless response.success?
          case response.code
          when 401
            raise InaccessibleFeed, 'TicketTailor API key is invalid or expired'
          when 403
            raise InaccessibleFeed, 'TicketTailor API key does not have permission to access events'
          when 429
            raise InaccessibleFeed, 'TicketTailor API rate limit exceeded. Please try again later.'
          else
            raise InaccessibleFeed, "TicketTailor API error (code=#{response.code})"
          end
        end

        response.body
      end
    end
  end
end
