# frozen_string_literal: true

module CalendarImporter::Events
  class WixEvent < Base
    imports title: 'title', description: %w[full_description description], start_time: 'scheduling.config.startDate',
            end_time: 'scheduling.config.endDate', repeats: nil,
            location: %w[location.fullAddress location.name location.address], webpage: 'slug', online_link: nil,
            spaces_available: nil, status: nil, image: 'mainImage.url', source_categories: 'categories.name',
            source_organiser: nil

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
