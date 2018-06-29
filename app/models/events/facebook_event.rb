# frozen_string_literal: true

module Events
  class FacebookEvent < Base
    def initialize(event)
      @event = OpenStruct.new(event)
    end

    def uid
      @event.id
    end

    def summary
      @event.name
    end

    def description
      @event.description
    end

    def place
      @event.place
    end

    def location
      return if place.blank?
      address = place['location']
      if address.present?
        [place['name'], address['street'], address['city'], address['zip']].reject(&:blank?).join(', ')
      else
        place['name']
      end
    end

    def dtstart
      DateTime.parse(@event.start_time)
    rescue StandardError
      nil
    end

    def dtend
      DateTime.parse(@event.end_time)
    rescue StandardError
      nil
    end

    def last_updated
      @event.updated_time
    end

    def recurring_event?
      @event.event_times.present?
    end

    def occurrences_between(*)
      @occurrences = []

      if recurring_event?
        @event.event_times.each { |times| @occurrences << Dates.new(times['start_time'], times['end_time']) }
      else
        @occurrences << Dates.new(dtstart, dtend)
      end

      @occurrences
    end
  end
end
