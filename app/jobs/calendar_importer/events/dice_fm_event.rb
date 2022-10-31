# frozen_string_literal: true

module CalendarImporter::Events
  class DiceFmEvent < Base
    attr_reader :full_type, :uid, :dtstart, :dtend, :summary, :description, :location

    def event_record?
      type == 'MusicEvent'
    end

    def initialize(event_hash)
      event_hash.each do |key, value|
        case key
        when '@type'
          @full_type = value.first

        when 'http://schema.org/description'
          @description = value.first['@value']

        when 'http://schema.org/endDate'
          @dtend = value.first['@value']

        when 'http://schema.org/startDate'
          @dtstart = value.first['@value']

        when 'http://schema.org/name'
          @summary = value.first['@value']

        when 'http://schema.org/url'
          url = value.first['@id']
          @uid = url

        when 'http://schema.org/location'
          location = value.first
          next unless location.present?

          address = location['http://schema.org/address']&.first
          next unless address.present?

          @location = address['@value']
        end
      end
    end

    def type
      @full_type.to_s.split('/').last
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end
  end
end
