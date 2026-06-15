# frozen_string_literal: true

module PanCal
  module Events
    # @api private
    class IcsEvent < PanCal::Event
      # Calendar custom properties that may contain online meeting URLs
      ONLINE_MEETING_PROPERTIES = %w[
        x_google_conference
        x_microsoft_skypeteamsmeetingurl
        x_microsoft_onlinemeetingconflink
        x_zoom_meeting_url
      ].freeze

      def initialize(event, start_date, end_date)
        super(event)
        @dtstart = start_date
        @dtend = end_date
      end

      attr_reader :dtstart, :dtend

      # to_s has to be called on any value returned by icalendar, or it will return a Icalendar::Values instead of a String
      def uid
        @event.uid.to_s
      end

      def summary
        @event.summary.to_s.strip
      end

      def description
        text = @event.description
        text = text.join(' ') if text.is_a?(Array)

        text.to_s
      end

      def location
        @event.location.to_s
      end

      delegate :rrule, to: :@event

      def last_updated
        @event.last_modified.to_s
      end

      def recurring_event?
        rrule.present?
      end

      delegate :occurrences_between, to: :@event

      # The iCal URL property links to more info about the event (its webpage),
      # not to an online meeting. Use this for publisher_url, not online detection.
      def publisher_url
        url = @event.url
        url = url.first if url.is_a?(Array)
        url.to_s.presence
      end

      def online_meeting_url
        link = online_meeting_custom_property
        link ||= maybe_location_is_link
        link ||= find_event_link_in_description

        link = link.first if link.is_a?(Array)
        link.to_s.presence
      end

      private

      def online_meeting_custom_property
        props = @event.custom_properties
        ONLINE_MEETING_PROPERTIES.lazy.filter_map { |key| props[key] }.first
      end

      def maybe_location_is_link
        return if location.blank?

        uri = URI.parse(location)
        return unless uri.scheme&.match?(/\Ahttps?\z/i)

        uri.to_s
      rescue URI::InvalidURIError
        nil
      end

      def find_event_link_in_description
        return if description.blank?

        ONLINE_MEETING_DOMAINS.each do |domain|
          match = description.match(url_regex_for(domain))
          return match[0] if match
        end
        nil
      end

      def url_regex_for(domain)
        # Matches URLs like: https://www.example.com/path or example.com/path
        escaped = Regexp.escape(domain)
        %r{(https?://)?([\w-]+\.)?#{escaped}/[^\s<"]+}
      end
    end
  end
end
