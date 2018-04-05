module Events
  class XmlEvent < DefaultEvent

    def initialize(event, start_date, end_date)
      @event = event
      @dtstart = start_date
      @dtend = end_date
    end

    attr_reader :dtstart, :dtend

    #to_s has to be called on any value returned by icalendar, or it will return a Icalendar::Values instead of a String
    def uid
      @event.attribute('id').text
    end

    def summary
      @event.css_at('name').text
    end

    def description
      @event.css_at('description').text.gsub(/\A(\n)+\z/, '')
    end

    def dstart

    end

    def dtend

    end

    def location
      ''
    end

    def recurring_event?
      false
    end

  end
end
