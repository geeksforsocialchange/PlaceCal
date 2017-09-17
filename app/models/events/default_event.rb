module Events
  class DefaultEvent

    def initialize(event)
      @event = event
    end

    def rrule
      nil
    end

    def attributes(start_time, end_time)
      { uid:         uid&.strip,
        dtstart:     start_time,
        dtend:       end_time,
        summary:     summary&.strip,
        description: description&.strip,
        location:    location&.strip,
        rrule:       rrule
      }
    end

    def recurring_event?
      false
    end

  end
end
