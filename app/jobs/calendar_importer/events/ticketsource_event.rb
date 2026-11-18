# frozen_string_literal: true

module CalendarImporter::Events
  class TicketsourceEvent < Base
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
