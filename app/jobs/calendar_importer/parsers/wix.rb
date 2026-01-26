# frozen_string_literal: true

module CalendarImporter
  module Parsers
    class Wix < Base
      NAME = 'Wix Events'
      KEY = 'wix'
      DOMAINS = %w[wixsite.com].freeze

      # NOTE: Wix sites often use custom domains, so this pattern
      # primarily catches wixsite.com subdomains. Custom domain
      # Wix sites should use importer_mode = 'wix' explicitly.
      def self.allowlist_pattern
        %r{^https://[^.]+\.wixsite\.com/}i
      end

      def download_calendar
        response_body = Base.read_http_source(@url)
        extract_wix_events(response_body)
      end

      def import_events_from(data)
        return [] unless data.is_a?(Array)

        data.filter_map do |event_data|
          next if event_data.dig('scheduling', 'config', 'scheduleTbd')

          Events::WixEvent.new(event_data, base_url: extract_base_url)
        end
      end

      private

      def extract_base_url
        uri = URI.parse(@url)
        "#{uri.scheme}://#{uri.host}"
      end

      # Extracts Wix event data from page HTML.
      #
      # Wix embeds event data in <script type="application/json"> tags rather than
      # exposing traditional feeds (iCal, RSS). This method parses the HTML, finds
      # all JSON script tags, and searches each one for Wix event structures.
      #
      # @param html [String] Raw HTML content from the Wix page
      # @return [Array<Hash>] Array of event hashes, or empty array if none found
      def extract_wix_events(html)
        doc = Nokogiri::HTML(html)

        doc.xpath('//script[@type="application/json"]').each do |script|
          json = parse_json_safely(script.inner_html)
          next unless json

          events = find_events_array(json)
          return events if events.present?
        end

        []
      end

      def parse_json_safely(string)
        JSON.parse(string)
      rescue JSON::ParserError
        nil
      end

      # Recursively searches through nested JSON to find a Wix events array.
      #
      # Wix's JSON structure varies and events can be deeply nested within the
      # page data. This method traverses the structure looking for an "events"
      # key containing an array of valid Wix event objects.
      #
      # @param json [Hash, Array] The JSON structure to search
      # @param depth [Integer] Current recursion depth (max 15 to prevent stack overflow)
      # @return [Array<Hash>, nil] The events array if found, nil otherwise
      def find_events_array(json, depth = 0)
        # Depth limit prevents stack overflow on malformed or circular-like structures
        return nil if depth > 15

        case json
        when Hash
          # Check if this hash has an "events" key with valid Wix events
          return json['events'] if json['events'].is_a?(Array) && wix_event?(json['events'].first)

          # Otherwise, recursively search all values
          json.each_value do |value|
            result = find_events_array(value, depth + 1)
            return result if result.present?
          end
        when Array
          # Search each item in the array
          json.each do |item|
            result = find_events_array(item, depth + 1)
            return result if result.present?
          end
        end

        nil
      end

      # Checks if a hash matches the Wix event signature.
      #
      # Wix events have a specific structure with required fields. This method
      # identifies valid events by checking for the presence of:
      # - id: unique event identifier
      # - title: event name
      # - scheduling.config.startDate: event start time
      #
      # @param hash [Hash] The hash to check
      # @return [Boolean] true if hash appears to be a Wix event
      def wix_event?(hash)
        return false unless hash.is_a?(Hash)

        hash['id'].present? &&
          hash['title'].present? &&
          hash.dig('scheduling', 'config', 'startDate').present?
      end
    end
  end
end
