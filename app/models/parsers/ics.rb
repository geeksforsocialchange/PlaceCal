# frozen_string_literal: true

module Parsers
  class Ics < DefaultParser
    def initialize(file, params={})
      @file = file
      @params = params
    end

    def self.whitelist_pattern
      /https:\/\/calendar.google.com\.*|https:\/\/outlook.office365.com\/owa\/calendar\/.*/
    end

    def events
      @events = []
      calendars = Icalendar::Calendar.parse(open(@file))

      # It is possible for an ics file to contain multiple calendars
      calendars.each do |calendar|
        calendar.events.each do |event|
          # Date can't be parsed with calling `value_ical` first
          @start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
          @end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

          @events << Events::IcsEvent.new(event, @start_time, @end_time)
        end
      end

      @events
    end

    def valid_file?
      url = URI.parse(@file)

      Net::HTTP.start(url.host, url.port) do |http|
        http.head(url.request_uri).code == '200'
      end
    rescue StandardError
      false
    end
  end
end
