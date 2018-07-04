# frozen_string_literal: true

module Parsers
  class Ics < Base

    def self.whitelist_pattern
      /http(s)?:\/\/calendar.google.com\.*|http(s)?:\/\/outlook.office365.com\/owa\/calendar\/.*|\Awebcal:\/\//
    end

    def download_calendar
      url = @url.gsub(/webcal:\/\//, 'https://') #Remove the webcal:// and just use the part after it
      open(url)
    end

    def import_events_from(data)
      @events = []

      # It is possible for an ics file to contain multiple calendars
      Icalendar::Calendar.parse(data).each do |calendar|
        calendar.events.each do |event|
          # Date can't be parsed with calling `value_ical` first
          @start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
          @end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

          @events << Events::IcsEvent.new(event, @start_time, @end_time)
        end
      end

      @events
    end

    def digest(data)
      #read file to get contents before creating digest
      Digest::MD5.hexdigest(data.read)
    end

  end
end
