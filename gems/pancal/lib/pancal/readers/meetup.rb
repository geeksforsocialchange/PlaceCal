# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class Meetup < Ics
      NAME = 'Meetup'
      KEY = 'meetup'
      DOMAINS = %w[www.meetup.com].freeze

      def self.allowlist_pattern
        %r{^https://www\.meetup\.com/[^/]*/?$}
      end

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
end
