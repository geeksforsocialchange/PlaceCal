# frozen_string_literal: true

module CalendarImporter
  module Events
    class SquarespaceEvent < Base
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
        "#{@event['url']}/#{@event['urlId']}"
      end

      # The dates provided are in UTC time which is milliseconds since January 1, 1970, 00:00:00 UTC.
      # Time.at accepts Unix time which is seconds since January 1, 1970, 00:00:00 UTC.
      # to account for this we just devide by 1000.
      def dtstart
        Time.zone.at(@event['startDate'] / 1000)
      end

      def dtend
        Time.zone.at(@event['endDate'] / 1000)
      end

      def occurrences_between(*)
        [Dates.new(dtstart, dtend)]
      end

      def location
        # get from partner??
        nil # TODO: ??? Why are we ignoring the venue for meetup events
      end
    end
  end
end
