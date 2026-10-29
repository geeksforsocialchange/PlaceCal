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
          next unless importable?(event_data)

          event_id = event_data['id']
          attrs = event_data['attributes']
          venue = fetch_event_venues(event_id).first

          (event_data['dates'] || []).filter_map do |date_data|
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

      # Dates are fetched here so they count towards the checksum, and a failed request fails the import.
      def fetch_all_events
        fetch_all_pages('/events').each do |event_data|
          next unless importable?(event_data)

          event_data['dates'] = fetch_all_pages("/events/#{event_data['id']}/dates").map { |date| date_fields(date) }
        end
      end

      # Only the fields the importer reads, so changes like ticket counts don't alter the checksum.
      def date_fields(date)
        { 'id' => date['id'], 'attributes' => (date['attributes'] || {}).slice('start', 'end', 'cancelled') }
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

      def importable?(event_data)
        attrs = event_data['attributes'] || {}
        !attrs['archived'] && attrs['public']
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
