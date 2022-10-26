# frozen_string_literal: true

module CalendarImporter::Events
  class SquarespaceEvent < Base
    def initialize(event)
      @event = event
    end

    def uid
      @event['id']
    end

    def summary
      @event['title']
    end

    def description
      @event['body']
    end

    def publisher_url
      # This gives the end part of url after "wewewe.squarespace.com/EVENTS/"
      @event['url'] + '/' + @event['urlId']
    end

    def dtstart
      Time.at(@event['startDate'] / 1000)
    end

    def dtend
      Time.at(@event['endDate'] / 1000)
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end

    def location
      #get from partner??
      return nil # TODO: ??? Why are we ignoring the venue for meetup events
    end
  end
end
