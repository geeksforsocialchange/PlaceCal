# frozen_string_literal: true

module CalendarImporter::Events
  class TicketsourceEvent < Base
    def uid
      "#{@event['id']}-#{@event.dig('date', 'id')}"
    end

    def summary
      @event.dig('attributes', 'name')
    end

    def description
      @event.dig('attributes', 'description') || ''
    end

    def dtstart
      value = @event.dig('date', 'attributes', 'start')
      Time.zone.parse(value) if value.present?
    end

    def dtend
      value = @event.dig('date', 'attributes', 'end')
      Time.zone.parse(value) if value.present?
    end

    def location
      venue = @event['venue']
      return nil unless venue.is_a?(Hash)

      attrs = venue['attributes'] || venue
      address = attrs['address'] || {}
      parts = [
        attrs['name'],
        address['line_1'],
        address['line_2'],
        address['line_3'],
        address['line_4'],
        address['postcode']
      ].compact_blank

      parts.join(', ').presence
    end

    def publisher_url
      @event['publisher_url']
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end
  end
end
