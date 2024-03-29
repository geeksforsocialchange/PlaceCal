# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Meetup < Base
    NAME = 'Meetup'
    KEY = 'meetup'
    DOMAINS = %w[www.meetup.com].freeze

    def self.allowlist_pattern
      %r{^https://www\.meetup\.com/[^/]*/?$}
    end

    def download_calendar
      user_name = (@url =~ %r{^https://www\.meetup\.com/([^/]*)/?$}) && Regexp.last_match(1)
      return [] if user_name.blank?

      api_url = "https://api.meetup.com/#{user_name}/events"
      response_body = Base.read_http_source(api_url)

      Base.safely_parse_json response_body
    end

    def import_events_from(data)
      data.map { |d| CalendarImporter::Events::MeetupEvent.new(d) }
    end
  end
end
