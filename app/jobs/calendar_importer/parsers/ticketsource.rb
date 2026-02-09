# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.
# Parent parser classes should not be added.

module CalendarImporter
  module Parsers
    class Ticketsource < ApiBase
      NAME = 'TicketSource'
      KEY = 'ticketsource'
      DOMAINS = %w[www.ticketsource.co.uk ticketsource.co.uk].freeze

      API_BASE_URL = 'https://api.ticketsource.io'
      USER_AGENT = 'ticketsource-placecal'

      # Match TicketSource venue pages like:
      # https://www.ticketsource.co.uk/fairfield-house
      # https://ticketsource.co.uk/some-venue
      def self.allowlist_pattern
        %r{^https://(www\.)?ticketsource\.co\.uk/[^/]+/?$}i
      end

      def user_agent
        USER_AGENT
      end

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.flat_map do |event_data|
          attrs = event_data['attributes'] || {}
          next if attrs['archived'] || !attrs['public']

          event_id = event_data['id']
          dates = fetch_event_dates(event_id)
          venues = fetch_event_venues(event_id)
          venue = venues.first

          dates.filter_map do |date_data|
            date_attrs = date_data['attributes'] || {}
            next if date_attrs['cancelled']

            merged = {
              'id' => event_id,
              'attributes' => attrs,
              'date' => date_data,
              'venue' => venue,
              'publisher_url' => build_publisher_url(event_data)
            }
            Events::TicketsourceEvent.new(merged)
          end
        end.compact
      end

      private

      def fetch_all_events
        events = []
        page = 1

        loop do
          url = build_events_url(page)
          response = fetch_page_json(url)
          page_events = response['data'] || []

          break if page_events.empty?

          events.concat(page_events)

          break unless response.dig('links', 'next')

          page += 1
        end

        events
      end

      def build_events_url(page = 1)
        "#{API_BASE_URL}/events?page=#{page}&per_page=100"
      end

      def fetch_event_dates(event_id)
        url = "#{API_BASE_URL}/events/#{event_id}/dates?per_page=100"
        response = fetch_page_json(url)
        response['data'] || []
      rescue StandardError => e
        Rails.logger.warn "#{NAME}: Failed to fetch dates for event #{event_id}: #{e.message}"
        []
      end

      def fetch_event_venues(event_id)
        url = "#{API_BASE_URL}/events/#{event_id}/venues"
        response = fetch_page_json(url)
        response['data'] || []
      rescue StandardError => e
        Rails.logger.warn "#{NAME}: Failed to fetch venues for event #{event_id}: #{e.message}"
        []
      end

      def build_publisher_url(event_data)
        ref = event_data.dig('attributes', 'reference')
        ref.present? ? "#{@url}/#{ref}" : @url
      end
    end
  end
end
