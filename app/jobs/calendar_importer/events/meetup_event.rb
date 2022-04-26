# frozen_string_literal: true

module CalendarImporter::Events
  class MeetupEvent < Base
    def initialize(event)
      @event = event
    end

    def uid
      @event['id']
    end

    def summary
      @event['name']
    end

    def description
      @event['description'] || ''
    end

    def place
      '' # N/A
    end

    def location
      return nil

      venue = @event['venue']
      if venue
        [
          venue['address_1'],
          venue['city'],
          venue['localized_country_name'],
          venue['name'] # postcode?
        ].map(&:to_s).map(&:strip).reject(&:blank?).join(', ')
      end
    end

    def dtstart
      ticks = @event['time'] + @event['utc_offset']
      Time.at(ticks / 1000)
    end

    def dtend
      dtstart + (@event['duration'] / 1000)
    end

    def occurrences_between(*)
      [ Dates.new(dtstart, dtend) ]
    end
  end
end
