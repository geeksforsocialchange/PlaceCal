# frozen_string_literal: true

module CalendarImporter::Events
  class TicketsolveEvent < Base
    def uid
      @event.attribute('id').text
    end

    def summary
      @event.at_css('name').text.gsub(/\A(\n)+\z/, '').strip
    end

    def description
      @event.at_css('description').text.gsub(/\A(\n)+\z/, '').strip
    end

    def location; end

    def footer
      "Tickets: #{@event.at_css('url').text}"
    end

    def recurring_event?
      true
    end

    def occurrences_between(*)
      @event.css('events').flat_map do |events|
        events.xpath('event').map do |event|
          Occurrence.new(start_time: Time.zone.parse(event.at_css('opening_time_iso').text),
                         status: event.at_css('status').text)
        end
      end
    end
  end
end
