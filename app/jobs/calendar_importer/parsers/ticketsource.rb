# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer.rb.
# Parent parser classes should not be added.

module CalendarImporter
  module Parsers
    class Ticketsource < Base
      NAME = 'TicketSource'
      KEY = 'ticketsource'
      DOMAINS = %w[www.ticketsource.co.uk ticketsource.co.uk].freeze

      # Match TicketSource venue pages like:
      # https://www.ticketsource.co.uk/fairfield-house
      # https://ticketsource.co.uk/some-venue
      def self.allowlist_pattern
        %r{^https://(www\.)?ticketsource\.co\.uk/[^/]+/?$}i
      end

      def download_calendar
        venue_html = fetch_with_browser_headers(@url)
        event_urls = extract_event_urls(venue_html)

        events_data = []
        seen_timeslots = Set.new

        event_urls.each do |event_url|
          event_html = fetch_page_safely(event_url)
          next unless event_html

          timeslot_urls = extract_timeslot_urls(event_html)

          timeslot_urls.each do |timeslot_url|
            # Skip if we've already processed this timeslot
            next if seen_timeslots.include?(timeslot_url)

            seen_timeslots.add(timeslot_url)

            timeslot_html = fetch_page_safely(timeslot_url)
            next unless timeslot_html

            json_ld = extract_json_ld_event(timeslot_html)
            events_data << json_ld if json_ld
          end
        end

        events_data
      end

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.filter_map do |event_json|
          Events::LinkedDataEvent.new(event_json)
        end
      end

      # Browser-like headers to avoid Cloudflare blocking
      BROWSER_HEADERS = {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language' => 'en-GB,en;q=0.9'
      }.freeze

      private

      def fetch_page_safely(url)
        fetch_with_browser_headers(url)
      rescue StandardError => e
        Rails.logger.warn "TicketSource: Failed to fetch #{url}: #{e.message}"
        nil
      end

      def fetch_with_browser_headers(url)
        response = HTTParty.get(
          url,
          headers: BROWSER_HEADERS,
          ssl_version: :TLSv1_2
        )
        return response.body if response.success?

        raise CalendarImporter::Exceptions::InaccessibleFeed,
              "The source URL could not be read (code=#{response.code})"
      end

      def extract_event_urls(html)
        doc = Nokogiri::HTML(html)
        base_uri = URI.parse(@url)

        # Find all links that match the event pattern /venue/event-name/e-xxxxx
        doc.css('a[href*="/e-"]').filter_map do |link|
          href = link['href']
          next unless href&.match?(%r{/e-[a-z0-9]+$}i)

          # Convert relative URLs to absolute
          if href.start_with?('/')
            "#{base_uri.scheme}://#{base_uri.host}#{href}"
          elsif href.start_with?('http')
            href
          end
        end.uniq
      end

      def extract_timeslot_urls(html)
        doc = Nokogiri::HTML(html)
        base_uri = URI.parse(@url)

        # Find all links that match the timeslot pattern /venue/event/date/time/t-xxxxx
        doc.css('a[href*="/t-"]').filter_map do |link|
          href = link['href']
          next unless href&.match?(%r{/t-[a-z0-9]+$}i)

          # Convert relative URLs to absolute
          if href.start_with?('/')
            "#{base_uri.scheme}://#{base_uri.host}#{href}"
          elsif href.start_with?('http')
            href
          end
        end.uniq
      end

      def extract_json_ld_event(html)
        doc = Nokogiri::HTML(html)

        doc.css('script[type="application/ld+json"]').each do |script|
          json = parse_json_safely(script.inner_html)
          next unless json

          # Find the Event object (may be at top level or nested)
          event = find_event_object(json)
          return normalize_event(event) if event
        end

        nil
      end

      def parse_json_safely(string)
        JSON.parse(string)
      rescue JSON::ParserError
        nil
      end

      def find_event_object(json, depth = 0)
        return nil if depth > 10

        case json
        when Hash
          # Check if this is an Event
          type = json['@type']
          return json if %w[Event http://schema.org/Event].include?(type)

          # Check @graph for events
          if json['@graph'].is_a?(Array)
            json['@graph'].each do |item|
              result = find_event_object(item, depth + 1)
              return result if result
            end
          end

          # Recurse into hash values
          json.each_value do |value|
            result = find_event_object(value, depth + 1)
            return result if result
          end
        when Array
          json.each do |item|
            result = find_event_object(item, depth + 1)
            return result if result
          end
        end

        nil
      end

      # Normalize TicketSource JSON-LD to the format expected by LinkedDataEvent
      def normalize_event(event)
        {
          'url' => event['url'],
          'name' => event['name'],
          'description' => event['description'],
          'start_date' => { '@value' => event['startDate'] },
          'end_date' => event['endDate'] ? { '@value' => event['endDate'] } : nil,
          'location' => normalize_location(event['location']),
          # LinkedDataEvent requires eventStatus to be present for not_cancelled? check
          # Default to Scheduled if not provided by TicketSource
          'http://schema.org/eventStatus' => event['eventStatus'] || 'https://schema.org/EventScheduled'
        }.compact
      end

      def normalize_location(location)
        return nil unless location.is_a?(Hash)

        address = location['address']
        return nil unless address.is_a?(Hash)

        {
          'address' => {
            'street_address' => address['streetAddress']
          }
        }
      end
    end
  end
end
