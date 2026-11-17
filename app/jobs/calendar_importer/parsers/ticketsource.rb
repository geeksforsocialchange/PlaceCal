# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.
# Parent parser classes should not be added.

module CalendarImporter
  module Parsers
    class Ticketsource < ApiBase
      NAME = 'TicketSource'
      KEY = 'ticketsource'
      DOMAINS = %w[www.ticketsource.co.uk ticketsource.co.uk www.ticketsource.com ticketsource.com].freeze

      API_BASE_URL = 'https://api.ticketsource.io'
      USER_AGENT = 'ticketsource-placecal'

      # Venue pages like https://www.ticketsource.co.uk/fairfield-house or https://www.ticketsource.com/mcr-balfolk
      def self.allowlist_pattern
        %r{^https://(www\.)?ticketsource\.(co\.uk|com)/[^/]+/?$}i
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

          (event_data['dates'] || []).filter_map do |date_data|
            date_attrs = date_data['attributes'] || {}
            next if date_attrs['cancelled']

            merged = {
              'id' => event_id,
              'attributes' => attrs,
              'date' => date_data,
              'venue' => event_data['venue'],
              'publisher_url' => build_publisher_url(event_data)
            }
            Events::TicketsourceEvent.new(merged)
          end
        end.compact
      end

      private

      # Dates and venues are fetched here so they count towards the checksum, and a failed request fails the import.
      def fetch_all_events
        fetch_all_pages('/events').each do |event_data|
          next unless importable?(event_data)

          event_data['dates'] = fetch_all_pages("/events/#{event_data['id']}/dates").map { |date| date_fields(date) }
          event_data['venue'] = venue_fields(fetch_event_venues(event_data['id']).first)
        end
      end

      # Only the fields the importer reads, so changes like ticket counts don't alter the checksum.
      def date_fields(date)
        { 'id' => date['id'], 'attributes' => (date['attributes'] || {}).slice('start', 'end', 'cancelled') }
      end

      def venue_fields(venue)
        return unless venue

        attrs = venue['attributes'] || {}
        address = (attrs['address'] || {}).slice('line_1', 'line_2', 'line_3', 'line_4', 'postcode')
        { 'attributes' => { 'name' => attrs['name'], 'address' => address } }
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
        fetch_page_json(url)['data'] || []
      rescue ApiNotFound
        []
      end

      def build_publisher_url(event_data)
        ref = event_data.dig('attributes', 'reference')
        ref.present? ? "#{@url.chomp('/')}/#{ref}" : @url
      end
    end
  end
end
