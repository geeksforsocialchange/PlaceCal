module Events
  class DefaultEvent

    Dates = Struct.new(:start_time, :end_time)

    def initialize(event)
      @event = event
    end

    attr_accessor :place_id, :address_id, :partner_id

    def rrule
      nil
    end

    def attributes
      { uid:         uid&.strip,
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

    def postcode
      postal = location.match(Address::POSTCODE_REGEX).try(:[], 0)
      postal = /M[1-9]{2}(?:\s)?(?:[1-9])?/.match(location).try(:[], 0) if postal.blank? #check for instances of M14 or M15 4 or whatever madness they've come up with

      if postal.blank?
        #See if Google returns a more informative address
        results = Geocoder.search(location)
        if results.first
          formatted_address = results.first.data["formatted_address"]

          postal = Address::POSTCODE_REGEX.match(formatted_address).try(:[], 0)
        end
      end

      postal
    end

    def ip_class
      @event&.ip_class
    end

    def private?
      (ip_class && ip_class.downcase == 'private') || (@event.description && @event.description.include?("#placecal-ignore"))
    end

  end
end
