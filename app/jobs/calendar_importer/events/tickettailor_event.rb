# frozen_string_literal: true

module CalendarImporter::Events
  class TickettailorEvent < Base
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

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end

    private

    def parse_datetime(time_hash)
      return nil unless time_hash.is_a?(Hash)

      date = time_hash['date']
      time = time_hash['time']
      timezone = time_hash['tz'] || 'UTC'

      return nil if date.blank?

      datetime_string = time.present? ? "#{date} #{time}" : date

      ActiveSupport::TimeZone[timezone]&.parse(datetime_string) ||
        DateTime.parse(datetime_string)
    rescue ArgumentError
      nil
    end
  end
end
