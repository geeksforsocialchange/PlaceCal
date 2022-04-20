# frozen_string_literal: true

module CallendarImporter::Events
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
      @event['description']['text']
    end

    def place
      @place ||= @event['venue']
    end

    def location
      return if place.blank?
      address = place['address']

      if address.present?
        [ place['name'],
          address['address_1'],
          address['address_2'],
          address['city'],
          address['region'],
          address['postal_code']
        ].reject(&:blank?).join(', ')
      else
        place['name']
      end
    end

    def dtstart
      DateTime.parse(@event['start']['local'])
    rescue StandardError
      nil
    end

    def dtend
      DateTime.parse(@event['end']['local'])
    rescue StandardError
      nil
    end

    def occurrences_between(*)
      #TODO: Expand when multi-day events supported
      @occurrences = []
      @occurrences << Dates.new(dtstart, dtend)
      @occurrences
    end

  end
end
