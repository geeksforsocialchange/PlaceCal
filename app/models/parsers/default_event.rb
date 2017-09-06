module Parsers
  class DefaultEvent

    def initialize(event)
      @event = event
    end

    def rrule
      nil
    end

    def attributes
      { uid:        uid,
        dtstart:    dtstart,
        dtend:      dtend,
        summary:    summary,
        description:description,
        location:   location,
        rrule:      rrule
      }
    end
  end
end
