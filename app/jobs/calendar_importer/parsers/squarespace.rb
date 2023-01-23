# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/jobs/calendar_importer/calendar_importer
# Parent parser classes should not be added.

module CalendarImporter
  module Parsers
    class Squarespace < Base
      # These constants are only used for the frontend interface
      NAME = 'Squarespace'
      KEY = 'squarespace'
      DOMAINS = %w[squarespace.com].freeze

      def self.allowlist_pattern
        %r{^https://.*\.squarespace\.com/[^/]*/?$}
      end

      def download_calendar
        json_url = @url
        json_url += '?format=json' unless json_url.ends_with?('?format=json')

        response_body = Base.read_http_source(json_url)
        # response = HTTParty.get(json_url)
        # return [] unless response.success?

        safely_parse_json response_body, []
      end

      def import_events_from(data)
        return [] unless data.is_a?(Hash)

        unless data['upcoming']
          Rails.logger.debug 'If you are seeing this it is likely that you are using the wrong URL'
          Rails.logger.debug 'or squarespace have changed their API'
          return []
        end
        data['upcoming'].map do |d|
          d['url'] = data['website']['baseUrl'] + data['collection']['fullUrl']
          # CalendarImporter::Events::SquarespaceEvent.new(d)
          Events::SquarespaceEvent.new(d)
        end
      end
    end
  end
end
