# frozen_string_literal: true

module CallendarImporter::Events
  class IcsEvent < Base
    def initialize(event, start_date, end_date)
      @event = event
      @dtstart = start_date
      @dtend = end_date
    end

    attr_reader :dtstart, :dtend

    # to_s has to be called on any value returned by icalendar, or it will return a Icalendar::Values instead of a String
    def uid
      @event.uid.to_s
    end

    def summary
      @event.summary.to_s.strip
    end

    def description
      @event.description.to_s.gsub(/\A(\n)+\z/, '').strip
    end

    def location
      @event.location.to_s
    end

    def rrule
      @event.rrule
    end

    def last_updated
      @event.last_modified.to_s
    end

    def recurring_event?
      rrule.present?
    end

    def occurrences_between(from, to)
      @event.occurrences_between(from, to)
    end
  end
end
