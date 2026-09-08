# frozen_string_literal: true

module CalendarImporter::Events
  class EventbriteEvent < Base
    def initialize(event)
      @event = event
    end

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

    # The venue only arrives via the `expand=venue` expansion. When Eventbrite
    # omits it the key is absent entirely, and the SDK's `[]` raises rather
    # than returning nil, so guard the lookup.
    def place
      @place ||= @event.respond_to?(:venue) ? @event['venue'] : nil
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
      @occurrences << Dates.new(dtstart, dtend)
      @occurrences
    end

    def online_event_id
      return unless @event['online_event']

      online_address = OnlineAddress.find_or_create_by(url: @event['url'], link_type: 'indirect')
      online_address.id
    end
  end
end
