module Events
  class IcsEvent < DefaultEvent

    def initialize(event, start_date, end_date)
      @event = event
      @dtstart = start_date
      @dtend = end_date
    end

    attr_reader :dtstart, :dtend

    def uid
      @event.uid
    end

    def summary
      @event.summary
    end

    def description
      @event.description.gsub(/\A(\n)+\z/, '')
    end

    def location
      @event.location
    end

    def rrule
      @event.rrule
    end

    def last_updated
      @event.last_modified
    end

    def recurring_event?
      rrule.present?
    end

    def occurrences_between(from, to)
      @event.occurrences_between(from, to)
    end

  end
end
