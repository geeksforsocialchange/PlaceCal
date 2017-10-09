module Events
  class FacebookEvent < DefaultEvent

    Dates = Struct.new(:start_time, :end_time)

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
        [ place['name'], address['street'], address['city'], address['zip'] ].reject(&:blank?).join(', ')
      else
        place['name']
      end
    end

    def dtstart
      @event.start_time
    end

    def dtend
      @event.end_time
    end

    def last_updated
      @event.updated_time
    end

    def recurring_event?
      @event.event_times.present?
    end

    def occurrences_between(*)
      @occurrences = []

      unless recurring_event?
        @occurrences << Dates.new(dtstart, dtend)
      else
        @event.event_times.each { |times| @occurrences << Dates.new(times["start_time"], times["end_time"]) }
      end

      @occurrences
    end
  end
end
