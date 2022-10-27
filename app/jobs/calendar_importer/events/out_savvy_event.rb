# frozen_string_literal: true

module CalendarImporter::Events
  class OutSavvyEvent < Base
    attr_reader :full_type

    attr_reader :uid,
      :summary,
      :description,
      :dtstart,
      :dtend,
      :location

    # def self.is_event_data?(data)
    #  return unless data.present?
      # return unless data['@context'].to_s == 'http://schema.org'
      # data['@type'] == 'Event' || data['@type'] == 'VisualArtsEvent'
    #  true
    #end

    def self.extract_location(value)
      location = value.first
      return unless location.present?

      address = location['http://schema.org/address']&.first
      return unless address.present?

      street_address = address['http://schema.org/streetAddress']
      return unless street_address.present?

      street_address&.first['@value']
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
          @url = value.first['@id']
          @uid = @url

        when 'http://schema.org/location'
          @location = OutSavvyEvent.extract_location(value)
        end
      end
    end

    def type
      @type ||= @full_type.split('/').last
    end

    def is_event_record?
      type == 'Event' || type == 'VisualArtsEvent'
    end

    def place
      ''
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end
  end
end
