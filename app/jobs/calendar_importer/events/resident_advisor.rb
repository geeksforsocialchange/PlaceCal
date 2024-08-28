# frozen_string_literal: true

module CalendarImporter::Events
  class ResidentAdvisor < Base
    def initialize(event)
      super
      @event = event
    end

    def uid
      @event['id']
    end

    def summary
      @event['title']
    end

    def description
      @event['content'] || ''
    end

    def place
      '' # N/A
    end

    def publisher_url
      "https://ra.co#{@event['contentUrl']}"
    end

    def location
      return @event['venue']['address'] if @event['venue']
    end

    def dtstart
      @event['startTime']
    end

    def dtend
      @event['endTime']
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end

    def online_event?
      return # I don't think RA supports online events

      # return unless @event['is_online_event']

      # online_address = OnlineAddress.find_or_create_by(url: @event['link'], link_type: 'indirect')
      # online_address.id
    end
  end
end
