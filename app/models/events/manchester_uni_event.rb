module Events
  class ZartsEvent < DefaultEvent
    def initialize(event)
      @event = event
    end

    def uid
      @event.attribute('id').text
    end

    def summary
      @event.at_css('ns:title').text.gsub(/\A(\n)+\z/, '').strip
    end

    def description
      @event.at_css('ns:description').text.gsub(/\A(\n)+\z/, '').strip
    end

    def location
     #ns:eventData > uom:location : gpp:building, gpp:city
      #ns:eventData > uom:location > gpp:geoLocation> gpp:point 
    end

    def dtstart
      DateTime.parse(@event.at_css('ns:times type='local'ns:start'))
    end

    def dtend
      DateTime.parse(@event.at_css('ns:times type='local'ns:start'))
    end

    def recurring_event?
      false
    end

    def occurrences_between(*)
      []
    end
  end
end
