# frozen_string_literal: true

module CalendarImporter::Events
  class LinkedDataEvent < Base
    attr_reader :uid, :start_time, :end_time, :summary, :description, :location

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
      address = address['street_address'] if address.is_a?(Hash)
      address
    end

    def initialize(data)
      super data

      @url = data['url']
      @description = data['description']
      @start_time = parse_timestamp(read_value_of(data, 'start_date'))
      @end_time = parse_timestamp(read_value_of(data, 'end_date'))
      @summary = data['name']
      @location = extract_location(data)

      @uid = @url
    end

    def attributes
      valid? && in_future? && super
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

    def occurrences_between(*)
      [Dates.new(start_time, end_time)]
    end
  end
end
