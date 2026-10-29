# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Ics < Base
    include CalendarImporter::Exceptions

    # Leaves out a VEVENT whose dates can't be read, so the rest of the feed still imports
    class SkippingParser < Icalendar::Parser
      DATE_ERRORS = [Icalendar::Values::Date::FormatError, Icalendar::Values::DateTime::FormatError].freeze

      def skipped
        @skipped ||= {}.compare_by_identity
      end

      def parse
        super.each { |calendar| calendar.events.reject! { |event| skipped.key?(event) } }
      end

      def parse_property(component, fields = nil)
        super
      rescue *DATE_ERRORS => e
        raise unless component.is_a?(Icalendar::Event)

        skipped[component] = e.message
      end
    end

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

    # Outlook names zones the Windows way, which icalendar can't resolve, so repeats keep one fixed offset
    WINDOWS_TIME_ZONES = {
      'GMT Standard Time' => 'Europe/London',
      'Greenwich Standard Time' => 'Atlantic/Reykjavik',
      'W. Europe Standard Time' => 'Europe/Berlin',
      'Romance Standard Time' => 'Europe/Paris',
      'Central Europe Standard Time' => 'Europe/Budapest',
      'Central European Standard Time' => 'Europe/Warsaw',
      'E. Europe Standard Time' => 'Europe/Chisinau',
      'GTB Standard Time' => 'Europe/Bucharest',
      'FLE Standard Time' => 'Europe/Kyiv',
      'Eastern Standard Time' => 'America/New_York',
      'Central Standard Time' => 'America/Chicago',
      'Pacific Standard Time' => 'America/Los_Angeles'
    }.freeze

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
      res = Base.read_http_source @url
      # sanatize google calendar to prevent each requesting resetting the checksum
      res.split("\n").reject { |l| l.include? 'DTSTAMP' }.join("\n")
    end

    def import_events_from(data)
      # It is possible for an ics file to contain multiple calendars
      vevents = parse_remote_calendars(data).flat_map(&:events)

      # A VEVENT with a RECURRENCE-ID replaces one occurrence of the series sharing its UID
      vevents.group_by { |event| event.uid.to_s }.values.flat_map do |group|
        overrides, series = group.partition(&:recurrence_id)
        next overrides.map { |event| ics_event(event) } if series.empty?

        series.map { |event| ics_event(event, overrides: overrides.map { |override| ics_event(override) }) }
      end
    end

    def parse_remote_calendars(data)
      raise InvalidResponse, 'Source returned empty ICS data' if data.blank?

      parser = SkippingParser.new(with_iana_time_zones(data))
      calendars = parser.parse
      parser.skipped.each do |event, error|
        notices << I18n.t('admin.calendars.importer.unreadable_event_dates', event: event.summary.to_s.presence || event.uid.to_s, error:)
      end
      calendars
    rescue RuntimeError, *SkippingParser::DATE_ERRORS => e
      raise InvalidResponse, "Could not parse ICS response (#{e})"
    end

    private

    def ics_event(event, overrides: [])
      use_local_time_for_unzoned_dates(event)
      # Date can't be parsed with calling `value_ical` first
      start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
      end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

      CalendarImporter::Events::IcsEvent.new(event, start_time, end_time, overrides:)
    end

    # All-day and floating times have no zone, and icalendar-recurrence would read them in the process zone
    def use_local_time_for_unzoned_dates(event)
      event.dtstart = local_time(event.dtstart)
      event.dtend = local_time(event.dtend)
      event.recurrence_id = local_time(event.recurrence_id)
      event.exdate = event.exdate.flat_map { |dates| Array(dates) }.map { |date| local_time(date) }
      event.rdate = event.rdate.flat_map { |dates| Array(dates) }.map { |date| local_time(date) }
    end

    def local_time(value)
      return value unless value.is_a?(Icalendar::Values::Date) || (value.is_a?(Icalendar::Values::DateTime) && value.ical_params['tzid'].blank?)

      Icalendar::Values::DateTime.new(value.strftime(Icalendar::Values::DateTime::FORMAT), 'tzid' => Time.zone.tzinfo.name)
    end

    def with_iana_time_zones(data)
      data.gsub(/(?<=TZID[=:])#{Regexp.union(WINDOWS_TIME_ZONES.keys)}/, WINDOWS_TIME_ZONES)
    end
  end
end
