# frozen_string_literal: true

module CalendarImporter::Events
  class LinkedDataEvent < Base
    EXCLUDED_STATUSES = %w[EventCancelled EventPostponed].freeze
    # Not in Parsers::Base::CONTEXT, so compacting leaves it under its full IRI
    KEYWORDS = 'http://schema.org/keywords'

    attr_reader :uid, :start_time, :end_time, :summary, :description, :location, :status

    alias dtstart start_time
    alias dtend end_time

    def initialize(data)
      super

      @url = data['url']
      @description = data['description']
      @start_time = parse_timestamp(read_value_of(data, 'start_date'))
      @end_time = parse_timestamp(read_value_of(data, 'end_date'))
      @summary = data['name']
      @location = extract_location(data)
      @status = data['http://schema.org/eventStatus']

      # Repeating events share a URL, so we need to add the starttime as a param.
      # Otherwise, PlaceCal will assume they're all the same event and update instead of create.
      @uid = "#{@url}?start=#{@start_time}"
    end

    def read_value_of(data, field_name)
      field_data = data[field_name]
      return unless field_data

      field_data['@value']
    end

    def parse_timestamp(value)
      DateTime.parse value.to_s
    rescue Date::Error
      nil
    end

    def extract_location(data)
      loc = data['location']
      return if loc.blank?

      address = loc['address']
      return loc['name'] unless address.is_a?(Hash)

      # Build full address from components
      components = [
        address['street_address'],
        address['address_locality'],
        address['address_region'],
        address['postal_code']
      ].compact_blank

      components.join(', ').presence || loc['name']
    end

    def valid?
      @url.present? &&
        @start_time.present? &&
        # @end_time.present &&
        @summary.present?
    end

    def in_future?
      @start_time.present? && (@start_time > DateTime.now)
    end

    # eventStatus is optional; postponed events have no date set yet, so the startDate shown would be wrong.
    def not_cancelled?
      status = @status.is_a?(Hash) ? @status['@id'] : @status
      EXCLUDED_STATUSES.exclude?(status.to_s.sub(%r{\A(https?://schema\.org/|schema:)}, ''))
    end

    def publisher_url
      @event['url']
    end

    # schema.org image is a URL, an ImageObject, or a list of either
    def image_url
      image = Array.wrap(@event['image_url']).first
      image.is_a?(Hash) ? image['@id'] || image['url'] : image
    end

    # keywords is one comma-separated string, or a list of strings or DefinedTerms
    def source_categories
      keywords = @event[KEYWORDS]
      return keywords.split(',') if keywords.is_a?(String)

      Array.wrap(keywords).flat_map { |keyword| named(keyword) }
    end

    def source_organiser
      Base.clean_list(Array.wrap(@event['organiser']).flat_map { |organiser| named(organiser) }).join(', ').presence
    end

    private

    def named(node)
      return [node] unless node.is_a?(Hash)

      Array.wrap(node.key?('@value') ? node['@value'] : node['name']).map { |name| name.is_a?(Hash) ? name['@value'] : name }
    end
  end
end
