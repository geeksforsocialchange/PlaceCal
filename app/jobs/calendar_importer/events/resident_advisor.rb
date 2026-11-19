# frozen_string_literal: true

module CalendarImporter::Events
  class ResidentAdvisor < Base
    imports title: 'title', description: 'content', start_time: 'startTime', end_time: 'endTime', repeats: nil,
            location: 'venue.address', webpage: 'contentUrl', online_link: nil, spaces_available: nil, status: 'title',
            image: nil, source_categories: nil, source_organiser: nil

    # RA marks a cancelled event only in its title, as "[CANCELLED] Name" or "[CANCELLED] - Name"
    CANCELLED_PREFIX = /\A\s*\[cancell?ed\]\s*\p{Pd}?\s*/i

    def uid
      @event['id']
    end

    def summary
      @event['title'].to_s.sub(CANCELLED_PREFIX, '')
    end

    def status
      @event['title'].to_s.match?(CANCELLED_PREFIX) ? 'cancelled' : 'scheduled'
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
