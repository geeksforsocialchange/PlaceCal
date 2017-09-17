module Events
  class FacebookEvent < DefaultEvent
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

  end
end
