module Parsers
  class IcsEvent < DefaultEvent

    def initialize(event, start_date, end_date)
      @event = event
      @dtstart = start_date
      @dtend = end_date
    end

    attr_reader :dtstart, :dtend

    def uid
      @event.uid.value_ical
    end

    def summary
      @event.summary.value_ical
    end

    def description
      @event.description.value_ical
    end

    def location
      @event.location.value_ical
    end

    def rrule
      @event.rrule
    end

    def last_updated
      @event.last_modified.value_ical
    end
  end
end
