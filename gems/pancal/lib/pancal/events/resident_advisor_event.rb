# frozen_string_literal: true

module PanCal
  module Events
    # @api private
    class ResidentAdvisorEvent < PanCal::Event
      def uid
        @event['id']
      end

      def summary
        @event['title']
      end

      def description
        @event['content'] || ''
      end

      def place
        '' # N/A
      end

      def publisher_url
        "https://ra.co#{@event['contentUrl']}"
      end

      def location
        @event['venue']['address'] if @event['venue']
      end

      def dtstart
        @event['startTime']
      end

      def dtend
        @event['endTime']
      end

      def occurrences_between(*)
        [Occurrence.new(dtstart, dtend)]
      end
    end
  end
end
