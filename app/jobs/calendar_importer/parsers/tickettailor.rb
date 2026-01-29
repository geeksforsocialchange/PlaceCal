# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.
# Parent parser classes should not be added.

module CalendarImporter
  module Parsers
    class Tickettailor < ApiBase
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

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.filter_map do |event_data|
          next unless event_data['status'] == 'published'

          Events::TickettailorEvent.new(event_data)
        end
      end

      private

      def fetch_all_events
        events = []
        starting_after = nil

        loop do
          url = build_events_url(starting_after)
          response = fetch_page_json(url)
          page_events = response['data'] || []

          break if page_events.empty?

          events.concat(page_events)

          next_link = response.dig('links', 'next')
          break unless next_link

          starting_after = page_events.last&.dig('id')
          break unless starting_after
        end

        events
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
    end
  end
end
