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

    def initialize(data)
      super data

      @url = data['url']
      return if @url.blank?

      @description = data['description']
      return if @description.blank?

      @start_time = parse_timestamp(read_value_of(data, 'start_date'))
      return if @start_time.blank?

      @end_time = parse_timestamp(read_value_of(data, 'end_date'))
      return if @end_time.blank?

      @summary = data['name']
      return if @summary.blank?

      loc = data['location']
      return if loc.blank?

      @location = loc['address']
      @location = @location['street_address'] if @location.is_a?(Hash)
      return if @location.blank?

      @uid = @url
      @is_valid = true
    end

    def attributes
      valid? && in_future? && super
    end

    def valid?
      @is_valid
    end

    def in_future?
      @start_time.present? && (@start_time > DateTime.now)
    end

    def occurrences_between(*)
      [Dates.new(start_time, end_time)]
    end
  end
end
