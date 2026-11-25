# frozen_string_literal: true

module CalendarImporter::Events
  class EventbriteEvent < Base
    imports title: 'name.text', description: 'description.html', start_time: 'start.utc', end_time: 'end.utc',
            repeats: nil, location: %w[venue.name venue.address], webpage: 'url', online_link: %w[online_event url],
            status: nil, image: 'logo.original.url', source_categories: nil, source_organiser: nil,
            ticket_url: nil, price: 'is_free', sold_out: nil

    def uid
      @event['id']
    end

    def summary
      @event['name']['text']
    end

    def description
      @event['description']['html']
    end

    def publisher_url
      @event['url']
    end

    def image_url
      @event.dig('logo', 'original', 'url')
    end

    # The event list gives no prices, only whether the event is free
    def price_from
      0 if @event['is_free'] == true
    end

    # Absent or null for events with no venue, such as online ones
    def place
      @place ||= @event['venue']
    end

    def location
      return if place.blank?

      address = place['address']

      if address.present?
        [
          place['name'],
          address['address_1'],
          address['address_2'],
          address['city'],
          address['region'],
          address['postal_code']
        ].compact_blank.join(', ')
      else
        place['name']
      end
    end

    def dtstart
      DateTime.parse(@event['start']['utc'])
    rescue StandardError
      nil
    end

    def dtend
      DateTime.parse(@event['end']['utc'])
    rescue StandardError
      nil
    end

    def online_event_id
      return unless @event['online_event']

      online_address = OnlineAddress.find_or_create_by(url: @event['url'], link_type: 'indirect')
      online_address.id
    end
  end
end
