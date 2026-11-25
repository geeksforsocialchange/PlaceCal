# frozen_string_literal: true

module CalendarImporter::Events
  class TicketsolveEvent < Base
    # A date's status; any other value leaves whether it's sold out unknown
    SOLD_OUT_STATUSES = { 'sold out' => true, 'available' => false }.freeze

    imports title: 'name', description: 'description', start_time: 'opening_time_iso', end_time: nil, repeats: nil,
            location: 'venue.name', webpage: 'url', online_link: nil, status: nil,
            image: 'images.image.url', source_categories: 'event_category', source_organiser: nil,
            ticket_url: nil, price: nil, sold_out: 'status'

    def uid
      @event.attribute('id').text
    end

    def summary
      child_text('name')
    end

    def description
      child_text('description')
    end

    # The feed lists each show under the venue it's at, which has a name but no address
    def location
      @event.ancestors('venue').first&.at_xpath('name')&.text.to_s.strip.presence
    end

    def publisher_url
      child_text('url').presence
    end

    def image_url
      image = @event.xpath('images/image').min_by { |node| node['priority'].to_i }
      image&.at_xpath('url[@size="large"]')&.text.to_s.strip.presence
    end

    def source_categories
      [child_text('event_category')].compact_blank
    end

    def recurring_event?
      true
    end

    def occurrences_between(*)
      @event.css('events').flat_map do |events|
        events.xpath('event').map do |event|
          Occurrence.new(start_time: Time.zone.parse(event.at_css('opening_time_iso').text),
                         sold_out: SOLD_OUT_STATUSES[event.at_css('status')&.text.to_s.strip.downcase])
        end
      end
    end

    private

    def child_text(name)
      @event.at_xpath(name)&.text.to_s.strip
    end
  end
end
