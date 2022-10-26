# frozen_string_literal: true

module CalendarImporter::Events
  class OutSavvyEvent < Base

    attr_reader :uid,
      :summary,
      :description,
      :dtstart,
      :dtend,
      :location

    def initialize(event_data)
      @event_data = event_data

      @context = @event_data['@context'].to_s
      @type = @event_data['@type'].to_s
      
      @uid = @event_data['url']
      @publisher_url = @event_data['url']
      @summary = @event_data['name']
      @description = @event_data['description']
      @dtstart = @event_data['startDate']
      @dtend = @event_data['endDate']

      location = @event_data['location']
      if location.present?
        address = location['address']
        if address.present? && address['@type'] == 'PostalAddress'
          @location = address['streetAddress']
        end
      end
    end

    def is_valid_event?
      return false if @context != 'http://schema.org'

      @type == 'Event' || @type == 'VisualArtsEvent'
    end

    def place
      ''
    end

    def occurrences_between(*)
      [Dates.new(dtstart, dtend]]
    end

    def online_event?
      false
    end
  end
end
