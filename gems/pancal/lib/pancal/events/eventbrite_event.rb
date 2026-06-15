# frozen_string_literal: true

module PanCal
  module Events
    # @api private
    class EventbriteEvent < PanCal::Event
      def uid
        @event['id']
      end

      def summary
        @event['name']['text']
      end

      def description
        @event['description']['html']
      end

      def publisher_url
        @event['url']
      end

      def place
        @place ||= @event['venue']
      end

      def location
        return if place.blank?

        address = place['address']

        if address.present?
          [
            place['name'],
            address['address_1'],
            address['address_2'],
            address['city'],
            address['region'],
            address['postal_code']
          ].compact_blank.join(', ')
        else
          place['name']
        end
      end

      def dtstart
        DateTime.parse(@event['start']['utc'])
      rescue StandardError
        nil
      end

      def dtend
        DateTime.parse(@event['end']['utc'])
      rescue StandardError
        nil
      end

      def occurrences_between(*)
        # TODO: Expand when multi-day events supported
        @occurrences = []
        @occurrences << Occurrence.new(dtstart, dtend)
        @occurrences
      end

      # Online Eventbrite events link to the event page rather than directly
      # to a meeting, so callers should treat this as an indirect link.
      def online_meeting_url
        return unless @event['online_event']

        @event['url']
      end
    end
  end
end
