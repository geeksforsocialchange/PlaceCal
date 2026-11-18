# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.

module CalendarImporter
  module Parsers
    class Ticketsource < ApiBase
      NAME = 'TicketSource'
      KEY = 'ticketsource'
      DOMAINS = %w[www.ticketsource.co.uk ticketsource.co.uk www.ticketsource.com ticketsource.com].freeze

      API_BASE_URL = 'https://api.ticketsource.io'
      USER_AGENT = 'ticketsource-placecal'
      ADDRESS_FIELDS = %w[line_1 line_2 line_3 line_4 postcode].freeze

      # Venue pages like https://www.ticketsource.co.uk/fairfield-house or https://www.ticketsource.com/mcr-balfolk
      def self.allowlist_pattern
        %r{^https://(www\.)?ticketsource\.(co\.uk|com)/[^/]+/?$}i
      end

      def user_agent
        USER_AGENT
      end

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.flat_map do |record|
          publisher_url = build_publisher_url(record)
          record['dates'].map do |date|
            Events::TicketsourceEvent.new(record, date, publisher_url:)
          end
        end
      end

      private

      # Dates and venues are fetched here so they count towards the checksum, and a failed request fails the import.
      def fetch_all_events
        fetch_all_pages('/events').select { |event| importable?(event) }.map { |event| event_record(event) }
      end

      # Only the fields the import reads, so changes like ticket counts don't alter the checksum
      def event_record(event)
        attrs = event['attributes']
        {
          'id' => event['id'],
          'name' => attrs['name'],
          'description' => attrs['description'],
          'reference' => attrs['reference'],
          'dates' => fetch_all_pages("/events/#{event['id']}/dates").map { |date| date_record(date) },
          'venue' => venue_record(fetch_event_venues(event['id']).first)
        }
      end

      def date_record(date)
        { 'id' => date['id'], **(date['attributes'] || {}).slice('start', 'end', 'cancelled') }
      end

      def venue_record(venue)
        return unless venue

        attrs = venue['attributes'] || {}
        { 'name' => attrs['name'], **(attrs['address'] || {}).slice(*ADDRESS_FIELDS) }
      end

      def fetch_all_pages(path)
        records = []
        page = 1

        loop do
          response = fetch_page_json("#{API_BASE_URL}#{path}?page=#{page}&per_page=100")
          page_records = response['data'] || []

          break if page_records.empty?

          records.concat(page_records)

          break unless response.dig('links', 'next')

          page += 1
        end

        records
      end

      def importable?(event)
        attrs = event['attributes'] || {}
        !attrs['archived'] && attrs['public']
      end

      def fetch_event_venues(event_id)
        url = "#{API_BASE_URL}/events/#{event_id}/venues"
        fetch_page_json(url)['data'] || []
      rescue ApiNotFound
        []
      end

      def build_publisher_url(record)
        ref = record['reference']
        ref.present? ? "#{@url.chomp('/')}/#{ref}" : @url
      end
    end
  end
end
