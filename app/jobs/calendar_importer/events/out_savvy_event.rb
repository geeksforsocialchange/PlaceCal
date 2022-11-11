# frozen_string_literal: true

module CalendarImporter::Events
  class OutSavvyEvent < Base
    ALLOWED_EVENT_TYPES = %w[
      Event
      BusinessEvent
      ChildrensEvent
      ComedyEvent
      CourseInstance
      DanceEvent
      DeliveryEvent
      EducationEvent
      EventSeries
      ExhibitionEvent
      Festival
      FoodEvent
      Hackathon
      LiteraryEvent
      MusicEvent
      PublicationEvent
      SaleEvent
      ScreeningEvent
      SocialEvent
      SportsEvent
      TheaterEvent
      VisualArtsEvent
    ].freeze

    attr_reader :full_type, :uid, :summary, :description, :dtstart, :dtend, :location

    def self.extract_location(value)
      location = value.first
      return if location.blank?

      address = location['http://schema.org/address']&.first
      return if address.blank?

      street_address = address['http://schema.org/streetAddress']
      return if street_address.blank?

      street_address&.first&.fetch('@value')
    end

    def initialize(event_hash)
      super event_hash

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

    def event_record?
      ALLOWED_EVENT_TYPES.include? type
    end

    def place
      ''
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend)]
    end
  end
end
