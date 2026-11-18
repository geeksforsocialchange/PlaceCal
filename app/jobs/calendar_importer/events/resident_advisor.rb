# frozen_string_literal: true

module CalendarImporter::Events
  class ResidentAdvisor < Base
    imports title: 'title', description: 'content', start_time: 'startTime', end_time: 'endTime', repeats: nil,
            location: 'venue.address', webpage: 'contentUrl', online_link: nil, spaces_available: nil, status: nil,
            image: nil, source_categories: nil, source_organiser: nil

    def uid
      @event['id']
    end

    def summary
      @event['title']
    end

    def description
      @event['content'] || ''
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
  end
end
