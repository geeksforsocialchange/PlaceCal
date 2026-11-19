# frozen_string_literal: true

module CalendarImporter::Events
  class TickettailorEvent < Base
    imports title: 'name', description: 'description', start_time: 'start.iso', end_time: 'end.iso', repeats: nil,
            location: %w[venue.name venue.postal_code], webpage: 'url', online_link: nil, spaces_available: nil,
            status: nil, image: 'images.header', source_categories: nil, source_organiser: nil

    def uid
      @event['id']
    end

    def summary
      @event['name']
    end

    def description
      @event['description'] || ''
    end

    def dtstart
      parse_datetime(@event['start'])
    end

    def dtend
      parse_datetime(@event['end'])
    end

    def location
      venue = @event['venue']
      return nil unless venue.is_a?(Hash)

      parts = [
        venue['name'],
        venue['postal_code']
      ].compact_blank

      parts.join(', ').presence
    end

    def publisher_url
      @event['url']
    end

    def image_url
      @event.dig('images', 'header')
    end

    private

    def parse_datetime(time_hash)
      return nil unless time_hash.is_a?(Hash)
      return Time.zone.iso8601(time_hash['iso']) if time_hash['iso'].present?

      date = time_hash['date']
      return nil if date.blank?

      # The event's own timezone names a zone; the time's "timezone" is only an offset
      zone = ActiveSupport::TimeZone[@event['timezone'].to_s] || Time.zone
      zone.parse([date, time_hash['time']].compact_blank.join(' '))
    rescue ArgumentError
      nil
    end
  end
end
