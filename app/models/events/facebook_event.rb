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
      address = place['location']
      if address.present?
        [ place['name'], address['street'], address['city'], address['zip'] ].reject(&:blank?).join(', ')
      else
        place['name']
      end
    end

    def dtstart
      DateTime.parse(@event.start_time)
    end

    def dtend
      DateTime.parse(@event.end_time)
    end

    def last_updated
      @event.updated_time
    end

    def recurring_event?
      @event.event_times.present?
    end

    def occurrences_between(from, to)
      @occurrences = []

      @event.event_times.each do |times|
        start_time = DateTime.parse(times["start_time"])

        if start_time >= from && start_time <= to
          @occurrences << Dates.new(start_time, DateTime.parse(times["end_time"]))
        end
      end

      @occurrences
    end
  end
end
