# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

require 'eventbrite_sdk'
require 'rest-client'

module PanCal
  module Readers
    class Eventbrite < Base
      NAME = 'Eventbrite'
      KEY = 'eventbrite'
      DOMAINS = %w[www.eventbrite.com www.eventbrite.co.uk].freeze

      def self.allowlist_pattern
        %r{^https://www\.eventbrite\.(com|co\.uk)/o/[A-Za-z0-9-]+}
      end

      def organizer_id
        path = URI.parse(@url).path
        path.split('/').last.split('-').last
      end

      def download_calendar
        EventbriteSDK.token = @source.token

        @events = []
        results = EventbriteSDK::Organizer.retrieve(id: organizer_id).events.with_expansion(:venue).page(1)

        loop do
          results.map do |event|
            html = get_event_description(EventbriteSDK.token, event.id)
            event.assign_attributes('description.html' => html)
          end
          @events += results
          results = results.next_page
          break if results.blank?
        end

        @events
      rescue RestClient::BadGateway
        []
      rescue EventbriteSDK::ResourceNotFound => e
        # The Eventbrite organiser no longer exists — usually deleted, or renamed
        # (which changes the numeric id baked into the source URL). Flag the
        # source as bad rather than letting the error bubble up unhandled.
        # Distinct from :not_found: the source URL itself may load fine in a
        # browser, so callers must not present this as a plain HTTP 404.
        raise InaccessibleFeed.new("Eventbrite organiser #{organizer_id} not found (#{e.message})",
                                   code: :organiser_not_found)
      end

      def import_events_from(data)
        data.map { |d| Events::EventbriteEvent.new(d) }
      end

      # Get full event description
      def get_event_description(token, event_id)
        resource = RestClient::Resource.new("https://www.eventbriteapi.com/v3/events/#{event_id}/description/")
        response = resource.get(Authorization: "Bearer #{token}")
        Base.safely_parse_json(response)['description']
      end
    end
  end
end
