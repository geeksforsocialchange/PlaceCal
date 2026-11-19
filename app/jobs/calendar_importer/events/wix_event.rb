# frozen_string_literal: true

module CalendarImporter::Events
  class WixEvent < Base
    imports title: 'title', description: %w[full_description description], start_time: 'scheduling.config.startDate',
            end_time: 'scheduling.config.endDate', repeats: nil,
            location: %w[location.fullAddress location.name location.address], webpage: 'slug', online_link: nil,
            spaces_available: nil, status: nil, image: 'mainImage.url', source_categories: 'categories.name',
            source_organiser: nil,
            ticket_url: nil, price: %w[registration.ticketing.lowestTicketPrice.value registration.ticketing.currency], sold_out: 'registration.ticketing.soldOut'

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
      @event['full_description'].presence || @event['description'] || ''
    end

    def publisher_url
      return unless @event['slug'] && @base_url

      "#{@base_url}/event-details/#{@event['slug']}"
    end

    def image_url
      image = @event['mainImage']
      image['url'] if image.is_a?(Hash)
    end

    # Wix documents each category as an object with a name; every recorded event's list is empty
    def source_categories
      Array.wrap(@event['categories']).map { |category| category.is_a?(Hash) ? category['name'] : category }
    end

    # lowestPrice is the formatted text, such as "£10.25"
    def price_from
      ticketing.dig('lowestTicketPrice', 'value')
    end

    def price_currency
      ticketing.dig('lowestTicketPrice', 'currency') || ticketing['currency']
    end

    def sold_out
      Base.boolean(ticketing['soldOut'])
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

    private

    def ticketing
      ticketing = @event.dig('registration', 'ticketing')
      ticketing.is_a?(Hash) ? ticketing : {}
    end

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
