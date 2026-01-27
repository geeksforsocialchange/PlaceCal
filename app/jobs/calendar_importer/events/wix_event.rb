# frozen_string_literal: true

module CalendarImporter::Events
  class WixEvent < Base
    def initialize(event, base_url: nil)
      super(event)
      @base_url = base_url
    end

    def uid
      @event['id']
    end

    def summary
      @event['title']
    end

    def description
      @event['description'] || ''
    end

    def publisher_url
      return unless @event['slug'] && @base_url

      "#{@base_url}/event-details/#{@event['slug']}"
    end

    def dtstart
      parse_timestamp(scheduling_config['startDate'])
    end

    def dtend
      parse_timestamp(scheduling_config['endDate'])
    end

    def location
      loc = @event['location']
      return nil unless loc.is_a?(Hash)

      # Use formatted address if available, otherwise build from parts
      loc.dig('fullAddress', 'formattedAddress') ||
        [loc['name'], loc['address']].compact_blank.join(', ')
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end

    private

    def scheduling_config
      @event.dig('scheduling', 'config') || {}
    end

    def parse_timestamp(timestamp)
      return nil if timestamp.blank?

      DateTime.parse(timestamp)
    rescue ArgumentError
      nil
    end
  end
end
