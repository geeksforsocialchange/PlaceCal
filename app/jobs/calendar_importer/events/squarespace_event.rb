# frozen_string_literal: true

module CalendarImporter::Events
  class SquarespaceEvent < Base
    imports title: 'title', description: 'body', start_time: 'startDate', end_time: 'endDate', repeats: nil,
            location: %w[location.addressTitle location.addressLine1 location.addressLine2], webpage: %w[website.baseUrl collection.fullUrl urlId],
            online_link: nil, spaces_available: nil, status: nil, image: 'assetUrl', source_categories: %w[categories tags],
            source_organiser: nil,
            ticket_url: nil, price: nil, sold_out: nil

    def uid
      @event['id']
    end

    def summary
      @event['title']
    end

    def description
      @event['body']
    end

    def publisher_url
      "#{@event['url']}/#{@event['urlId']}"
    end

    def image_url
      @event['assetUrl']
    end

    def source_categories
      Array(@event['categories']) + Array(@event['tags'])
    end

    # The dates provided are in UTC time which is milliseconds since January 1, 1970, 00:00:00 UTC.
    # Time.at accepts Unix time which is seconds since January 1, 1970, 00:00:00 UTC.
    # to account for this we just devide by 1000.
    def dtstart
      Time.zone.at(@event['startDate'] / 1000)
    end

    def dtend
      Time.zone.at(@event['endDate'] / 1000)
    end

    def location
      venue = @event['location']
      return nil unless venue.is_a?(Hash)

      # Not addressCountry: the location resolver would keep a country name as a street line
      # Squarespace HTML-escapes text fields, and a venue picked from map search repeats its street as its title
      venue.values_at('addressTitle', 'addressLine1', 'addressLine2')
           .map { |part| CGI.unescapeHTML(part.to_s).strip }
           .compact_blank
           .uniq(&:downcase)
           .join(', ')
           .presence
    end
  end
end
