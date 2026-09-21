# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Meetup < Ics
    NAME = 'Meetup'
    KEY = 'meetup'
    DOMAINS = %w[www.meetup.com].freeze

    # Match Meetup group pages (not individual event pages) like:
    # https://www.meetup.com/group-name
    URL_PATTERNS = [
      { pattern: '^https://www\.meetup\.com/[^/]*/?$', flags: '' }
    ].freeze

    def download_calendar
      group_name = (@url =~ %r{^https://www\.meetup\.com/([^/]*)/?$}) && Regexp.last_match(1)
      return [] if group_name.blank?

      ical_url = "https://www.meetup.com/#{group_name}/events/ical"
      res = Base.read_http_source(ical_url)

      # Remove DTSTAMP to prevent checksum changes on each request
      res.split("\n").reject { |l| l.include? 'DTSTAMP' }.join("\n")
    end
  end
end
