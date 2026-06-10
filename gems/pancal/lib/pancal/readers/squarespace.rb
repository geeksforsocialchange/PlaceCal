# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class Squarespace < Base
      # These constants are only used for the frontend interface
      NAME = 'Squarespace'
      KEY = 'squarespace'
      DOMAINS = %w[squarespace.com].freeze

      def self.allowlist_pattern
        %r{^https://.*\.squarespace\.com/[^/]*/?$}
      end

      def self.handles_url?(source)
        url = source.url
        return true if url.match?(%r{^https://[^.]+\.squarespace\.com/}i)

        # For custom domains, check if page has Squarespace marker and events JSON
        squarespace_site?(url)
      rescue StandardError
        false
      end

      def self.squarespace_site?(url)
        response_body = Base.read_http_source(url)
        return false unless squarespace_page?(response_body)

        # Verify the JSON endpoint returns events
        squarespace_events?(url)
      end

      def self.squarespace_page?(html)
        # Check for Squarespace markers - either the comment or the CDN preconnect link
        html.include?('<!-- This is Squarespace. -->') ||
          html.include?('href="https://images.squarespace-cdn.com"')
      end

      def self.squarespace_events?(url)
        json_url = url.include?('?') ? "#{url}&format=json" : "#{url}?format=json"
        response_body = Base.read_http_source(json_url)
        json = Base.safely_parse_json(response_body)
        json.is_a?(Hash) && (json['upcoming'].present? || json['past'].present?)
      rescue StandardError
        false
      end

      def download_calendar
        json_url = @url
        json_url += '?format=json' unless json_url.ends_with?('?format=json')

        response_body = Base.read_http_source(json_url)
        Base.safely_parse_json response_body
      end

      def import_events_from(data)
        return [] unless data.is_a?(Hash)

        unless data['upcoming']
          logger.debug 'If you are seeing this it is likely that you are using the wrong URL'
          logger.debug 'or squarespace have changed their API'
          return []
        end
        data['upcoming'].map do |d|
          d['url'] = data['website']['baseUrl'] + data['collection']['fullUrl']
          Events::SquarespaceEvent.new(d)
        end
      end
    end
  end
end
