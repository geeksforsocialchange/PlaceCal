# frozen_string_literal: true

module CalendarImporter::Events
  class TickettailorEvent < Base
    imports title: 'name', description: 'description', start_time: 'start', end_time: 'end', repeats: nil,
            location: %w[venue.name venue.postal_code], webpage: 'url', online_link: nil, spaces_available: nil,
            status: nil, image: 'images.header', source_categories: nil, source_organiser: nil,
            ticket_url: 'checkout_url', price: %w[ticket_types.price currency], sold_out: %w[tickets_available unavailable_status]

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

    def ticket_url
      @event['checkout_url']
    end

    # Prices are in pence; ticket types on sale count over ones that aren't
    def price_from
      types = Array.wrap(@event['ticket_types']).select { |type| type.is_a?(Hash) && type['price'].is_a?(Integer) }
      on_sale = types.select { |type| type['status'] == 'on_sale' }
      lowest = (on_sale.presence || types).pluck('price').min
      BigDecimal(lowest) / 100 if lowest
    end

    def price_currency
      @event['currency']
    end

    # tickets_available is also "false" before sales open and after they close, so only a sold-out status says sold out
    def sold_out
      return true if @event['unavailable_status'].to_s.match?(/sold.?out/i)

      false if Base.boolean(@event['tickets_available'])
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
