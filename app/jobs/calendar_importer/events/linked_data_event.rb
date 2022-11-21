# frozen_string_literal: true

module CalendarImporter::Events
  class LinkedDataEvent < Base
    attr_reader :uid, :start_time, :end_time, :summary, :description, :location

    def read_value_of(data, field_name)
      field_data = data[field_name]
      return unless field_data

      field_data['@value']
    end

    def initialize(data)
      super data

      @url = data['url']
      return if @url.blank?

      @description = data['description']
      return if @description.blank?

      @start_time = read_value_of(data, 'start_date')
      return if @start_time.blank?

      @end_time = read_value_of(data, 'end_date')
      return if @end_time.blank?

      @summary = data['name']
      return if @summary.blank?

      loc = data['location']
      return if loc.blank?

      @location = loc['address']
      return if @location.blank?

      @uid = @url
      @is_valid = true
    end

    def attributes
      valid? && super
    end

    def valid?
      @is_valid
    end

    def occurrences_between(*)
      [Dates.new(start_time, end_time)]
    end
  end
end
