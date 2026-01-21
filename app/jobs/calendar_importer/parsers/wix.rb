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

      def find_events_array(json, depth = 0)
        return nil if depth > 15

        case json
        when Hash
          # Direct events array with Wix event structure
          return json['events'] if json['events'].is_a?(Array) && wix_event?(json['events'].first)

          json.each_value do |value|
            result = find_events_array(value, depth + 1)
            return result if result.present?
          end
        when Array
          json.each do |item|
            result = find_events_array(item, depth + 1)
            return result if result.present?
          end
        end

        nil
      end

      def wix_event?(hash)
        return false unless hash.is_a?(Hash)

        hash['id'].present? &&
          hash['title'].present? &&
          hash.dig('scheduling', 'config', 'startDate').present?
      end
    end
  end
end
