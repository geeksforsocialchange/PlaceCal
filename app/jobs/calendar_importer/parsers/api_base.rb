# frozen_string_literal: true

# Base class for parsers that use authenticated REST APIs.
# Provides shared auth, HTTP request handling, and error mapping.
# Subclasses must implement: fetch_all_events, import_events_from

module CalendarImporter
  module Parsers
    class ApiBase < Base
      def self.requires_api_token?
        true
      end

      def download_calendar
        validate_api_key!
        fetch_all_events
      end

      private

      def api_key
        @calendar.api_token
      end

      # Override in subclasses to set a custom User-Agent header
      def user_agent
        nil
      end

      def validate_api_key!
        return if api_key.present?

        raise InaccessibleFeed,
              "#{self.class::NAME} API key required. Please add your API key to the calendar settings."
      end

      def make_api_request(url)
        encoded_key = Base64.strict_encode64("#{api_key}:")

        headers = {
          'Accept' => 'application/json',
          'Authorization' => "Basic #{encoded_key}"
        }
        headers['User-Agent'] = user_agent if user_agent

        response = HTTParty.get(url, headers: headers)

        unless response.success?
          case response.code
          when 401
            raise InaccessibleFeed, "#{self.class::NAME} API key is invalid or expired"
          when 403
            raise InaccessibleFeed, "#{self.class::NAME} API key does not have permission to access events"
          when 429
            raise InaccessibleFeed, "#{self.class::NAME} API rate limit exceeded. Please try again later."
          else
            raise InaccessibleFeed, "#{self.class::NAME} API error (code=#{response.code})"
          end
        end

        response.body
      end

      def fetch_page_json(url)
        Base.safely_parse_json(make_api_request(url))
      end
    end
  end
end
