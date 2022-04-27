# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Ics < Base
    NAME = 'ICS'
    DOMAINS = %w[
      calendar.google.com
      outlook.office365.com
      outlook.live.com
      ics.teamup.com
    ]

    def self.whitelist_pattern
      /http(s)?:\/\/calendar.google.com\.*|http(s)?:\/\/outlook.(office365|live).com\/owa\/calendar\/.*|\Awebcal:\/\/|http:\/\/mossleycommunitycentre.org.uk|http:\/\/www.theproudtrust.org|http(s)?:\/\/ics.teamup.com\/feed\/.*/
    end

    def download_calendar
      url = @url.gsub(/webcal:\/\//, 'https://') #Remove the webcal:// and just use the part after it
      HTTParty.get(url, follow_redirects: true)
    end

    def import_events_from(data)
      @events = []

      # It is possible for an ics file to contain multiple calendars
      Icalendar::Calendar.parse(data).each do |calendar|
        calendar.events.each do |event|
          # Date can't be parsed with calling `value_ical` first
          @start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
          @end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

          @events << CalendarImporter::Events::IcsEvent.new(event, @start_time, @end_time)
        end
      end

      @events
    end

    def digest(data)
      #read file to get contents before creating digest
      Digest::MD5.hexdigest(data)
    end

  end
end
