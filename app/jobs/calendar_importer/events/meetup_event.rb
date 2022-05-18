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

    def publisher_url
      @event['link']
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
      if @event['duration'].nil?
        dtstart + 1.hour
      else
        dtstart + (@event['duration'] / 1000)
      end
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end

    def online_event?
      return unless @event['is_online_event']

      online_address = OnlineAddress.find_or_create_by(url: @event['link'])
      online_address.id
    end
  end
end
