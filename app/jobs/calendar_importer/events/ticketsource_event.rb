# frozen_string_literal: true

module CalendarImporter::Events
  class TicketsourceEvent < Base
    imports title: 'name', description: 'description', start_time: 'dates.start', end_time: 'dates.end', repeats: nil,
            location: %w[venue.name venue.address], webpage: 'reference', online_link: nil, spaces_available: nil,
            status: 'dates.cancelled', image: 'images.src', source_categories: %w[keywords category genre],
            source_organiser: nil

    VENUE_FIELDS = ['name', *CalendarImporter::Parsers::Ticketsource::ADDRESS_FIELDS].freeze

    attr_reader :publisher_url

    def initialize(record, date, publisher_url:)
      super(record)
      @date = date
      @publisher_url = publisher_url
    end

    def uid
      "#{@event['id']}-#{@date['id']}"
    end

    def summary
      @event['name']
    end

    def description
      @event['description'] || ''
    end

    def dtstart
      parse_time(@date['start'])
    end

    def status
      @date['cancelled'] ? 'cancelled' : 'scheduled'
    end

    def dtend
      parse_time(@date['end'])
    end

    def image_url
      Array.wrap(@event['images']).first
    end

    # keywords is documented as one string, read here as a comma-separated list
    def source_categories
      [*@event['keywords'].to_s.split(','), @event['category'], @event['genre']].compact_blank
    end

    def location
      venue = @event['venue']
      return unless venue

      venue.values_at(*VENUE_FIELDS).compact_blank.join(', ').presence
    end

    private

    def parse_time(value)
      Time.zone.parse(value) if value.present?
    end
  end
end
