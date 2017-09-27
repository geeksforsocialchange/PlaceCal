module Events
  class DefaultEvent

    def initialize(event)
      @event = event
    end

    attr_accessor :place_id, :address_id, :partner_id

    def rrule
      nil
    end

    def attributes(start_time, end_time)
      { uid:         uid&.strip,
        dtstart:     start_time,
        dtend:       end_time,
        summary:     summary&.strip,
        description: description&.strip,
        location:    location&.strip,
        rrule:       rrule,
        place_id:    place_id,
        address_id:  address_id,
        partner_id:  partner_id
      }
    end

    def recurring_event?
      false
    end

  end
end
