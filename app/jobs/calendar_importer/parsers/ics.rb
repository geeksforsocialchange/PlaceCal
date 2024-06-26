# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Ics < Base
    include CalendarImporter::Exceptions

    # These constants are only used for the frontend interface
    NAME = 'Generic iCal / .ics'
    KEY = 'ical'
    DOMAINS = %w[
      calendar.google.com
      outlook.office365.com
      outlook.live.com
      ics.teamup.com
      webcal://
    ].freeze

    def self.allowlist_pattern
      allowlists = {
        gcal: %r{^https?://calendar\.google\.com.*},
        outlook: %r{^https?://outlook\.(office365|live)\.com/owa/calendar/.*},
        webcal: %r{^webcal://},
        mossley: %r{^https?://mossleycommunitycentre\.org\.uk},
        teamup: %r{^https?://ics\.teamup\.com/feed/.*},
        consortium: %r{^https://www\.consortium\.lgbt/events/.*},
        generic: %r{^https?://.*\.ics$}
      }
      Regexp.union(allowlists.values)
    end

    def download_calendar
      # Why are we doing this?
      url = @url.gsub(%r{webcal://}, 'https://') # Remove the webcal:// and just use the part after it
      res = Base.read_http_source url
      # sanatize google calendar to prevent each requesting resetting the checksum
      res.split("\n").reject { |l| l.include? 'DTSTAMP' }.join("\n")
    end

    def import_events_from(data)
      @events = []

      # It is possible for an ics file to contain multiple calendars
      parse_remote_calendars(data).each do |calendar|
        calendar.events.each do |event|
          # Date can't be parsed with calling `value_ical` first
          @start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
          @end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

          @events << CalendarImporter::Events::IcsEvent.new(event, @start_time, @end_time)
        end
      end

      @events
    end

    def parse_remote_calendars(data)
      raise InvalidResponse, 'Source returned empty ICS data' if data.blank?

      Icalendar::Calendar.parse data
    rescue RuntimeError => e
      # I hope this isn't swallowing up any important exceptions.

      # From the PR comment describing this:
      #   The icalendar gem appears to lack a distinct exception class.
      #   As for investigating- i think you'd have to trace the code path
      #   manually and see how the ICS parser tests for errors. so if
      #   there is a problem it will likely be in that code (or our input
      #   into it, which is tested on the line above). at least it is not
      #   catching StandardError.
      #   - IK

      raise InvalidResponse, "Could not parse ICS response (#{e})"
    end
  end
end
