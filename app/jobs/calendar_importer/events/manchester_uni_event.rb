module CalendarImporter::Events
  class ManchesterUniEvent < Base
    def initialize(event)
      @event = event
    end

    def uid
      @event.at_xpath("./ns:id").text
    end

    def summary
      @event.at_xpath("./ns:title").text.gsub(/\A(\n)+\z/, "").strip
    end

    def description
      @event.at_xpath("./ns:description").text.gsub(/\A(\n)+\z/, "").strip
    end

    def location
    end

    def dtstart
      date = @event.at_xpath('./ns:times[@type="local"] //ns:start //ns:date')
      time = @event.at_xpath('./ns:times[@type="local"] //ns:start //ns:time')
      DateTime.parse([date, time].join(", "))
    rescue StandardError
      nil
    end

    def dtend
      date = @event.at_xpath('./ns:times[@type="local"] //ns:end //ns:date')
      time = @event.at_xpath('./ns:times[@type="local"] //ns:end //ns:time')
      DateTime.parse([date, time].join(", "))
    rescue StandardError
      nil
    end

    def recurring_event?
      false
    end

    def occurrences_between(*)
      # TODO: Expand when multi-day events supported
      @occurrences = []
      @occurrences << Dates.new(dtstart, dtend)
      @occurrences
    end
  end
end
