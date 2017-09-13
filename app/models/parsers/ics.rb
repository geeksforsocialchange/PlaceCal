module Parsers
  class Ics
    def initialize(file)
      @file = file
    end

    def events
      @events = []
      calendars = Icalendar::Calendar.parse(open(@file))

      # It is possible for an ics file to contain multiple calendars
      calendars.each do |calendar|
        calendar.events.each do |event|
          if event.rrule.present?
            event.occurrences_between(Date.today, 1.year.from_now).each do |occurrence|
              @events << IcsEvent.new(event, occurrence.start_time, occurrence.end_time)
            end
          else
            #Date can't be parsed with calling `value_ical` first
            @start_time = DateTime.parse(event.dtstart.value_ical) if event.dtstart
            @end_time = DateTime.parse(event.dtend.value_ical) if event.dtend

            @events << IcsEvent.new(event, @start_time, @end_time)
          end
        end
      end

      @events
    end

    def valid_file?
      url = URI.parse(@file)

      Net::HTTP.start(url.host, url.port) do |http|
        http.head(url.request_uri).code == '200'
      end

    rescue
      return false
    end
  end
end
