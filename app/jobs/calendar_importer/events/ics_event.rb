# frozen_string_literal: true

module CalendarImporter::Events
  class IcsEvent < Base
    class MissingTypeForURL < StandardError; end

    def initialize(event, start_date, end_date)
      @event = event
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
      text = text.join(' ') if text.is_a?(::Array)

      text.to_s # .gsub(/\A(\n)+\z/, '').strip
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

    def online_event_id
      # Check for actual online meeting links - NOT the event URL property
      # which is just a link to more info about the event
      link = online_meeting_custom_property
      link ||= maybe_location_is_link
      link ||= find_event_link

      link = link.first if link.is_a?(Array)
      link = link.to_s

      return if link.blank?

      online_address = OnlineAddress.find_or_create_by(url: link,
                                                       link_type: have_direct_url_to_stream?(link))
      online_address.id
    end

    private

    # Check for calendar-specific custom properties that contain online meeting URLs
    # Different calendar providers use different property names
    def online_meeting_custom_property
      props = @event.custom_properties
      # Google Calendar
      props['x_google_conference'] ||
        # Microsoft Outlook/Teams
        props['x_microsoft_skypeteamsmeetingurl'] ||
        props['x_microsoft_onlinemeetingconflink'] ||
        # Zoom calendar integration
        props['x_zoom_meeting_url']
    end

    def maybe_location_is_link
      return if location.blank?

      uri = URI.parse(location)
      # Only accept http/https URLs - URI.parse accepts any string as a relative path
      return unless uri.scheme&.match?(/\Ahttps?\z/i)

      uri.to_s
    rescue URI::InvalidURIError
      # no URL found
    end

    def have_direct_url_to_stream?(link)
      domain = event_link_types.keys.find { |domain| link.include?(domain) }

      return event_link_types[domain][:type] if domain

      'indirect'
    end

    def find_event_link
      link_regexes = event_link_types.values.pluck(:regex)
      regex = Regexp.union link_regexes

      regex.match(description).to_a
    end

    def event_link_types
      # this only detects "direct" link types now and everything else is "indirect"

      http = %r{(http(s)?://)?} # - https:// or http:// or nothing
      alphanum = /[A-Za-z0-9]+/      # - alphanumeric strings
      subdomain = /(#{alphanum}\.)?/ # - matches the www. or us04web in the zoom link
      suffix = /[^\s<"]+/            # - matches until we see a whitespace character,
      #   an angle bracket, or a quote (thanks html)

      # We deal with the following strings:
      #   meet.jit.si/foobarbaz
      #   meet.google.com/kbv-byuf-cvq
      #   us04web.zoom.us/j/(really long url)
      #   zoom.us/j/(really long url)
      # We also deal with strings like
      #   <a href="(event url)">
      #   <p>(event url)</p>

      {
        # Video conferencing
        'meet.jit.si' => { regex: %r{#{http}#{subdomain}meet.jit.si/#{suffix}}, type: 'direct' },
        'meet.google.com' => { regex: %r{#{http}#{subdomain}meet.google.com/#{suffix}}, type: 'direct' },
        'zoom.us' => { regex: %r{#{http}#{subdomain}zoom.us/j/#{suffix}}, type: 'direct' },
        'teams.microsoft.com' => { regex: %r{#{http}#{subdomain}teams.microsoft.com/#{suffix}}, type: 'direct' },
        'teams.live.com' => { regex: %r{#{http}#{subdomain}teams.live.com/#{suffix}}, type: 'direct' },
        'webex.com' => { regex: %r{#{http}#{subdomain}webex.com/#{suffix}}, type: 'direct' },
        'gotomeet.me' => { regex: %r{#{http}gotomeet.me/#{suffix}}, type: 'direct' },
        'gotomeeting.com' => { regex: %r{#{http}#{subdomain}gotomeeting.com/#{suffix}}, type: 'direct' },
        'discord.gg' => { regex: %r{#{http}discord.gg/#{suffix}}, type: 'direct' },
        'discord.com' => { regex: %r{#{http}#{subdomain}discord.com/#{suffix}}, type: 'direct' },

        # Live streaming
        'youtube.com' => { regex: %r{#{http}#{subdomain}youtube.com/#{suffix}}, type: 'direct' },
        'youtu.be' => { regex: %r{#{http}youtu.be/#{suffix}}, type: 'direct' },
        'twitch.tv' => { regex: %r{#{http}#{subdomain}twitch.tv/#{suffix}}, type: 'direct' },
        'vimeo.com' => { regex: %r{#{http}#{subdomain}vimeo.com/#{suffix}}, type: 'direct' },
        'facebook.com' => { regex: %r{#{http}#{subdomain}facebook.com/#{suffix}}, type: 'direct' },
        'fb.watch' => { regex: %r{#{http}fb.watch/#{suffix}}, type: 'direct' },
        'instagram.com' => { regex: %r{#{http}#{subdomain}instagram.com/#{suffix}}, type: 'direct' },
        'linkedin.com' => { regex: %r{#{http}#{subdomain}linkedin.com/video/#{suffix}}, type: 'direct' },

        # Webinar platforms
        'crowdcast.io' => { regex: %r{#{http}#{subdomain}crowdcast.io/#{suffix}}, type: 'direct' },
        'streamyard.com' => { regex: %r{#{http}#{subdomain}streamyard.com/#{suffix}}, type: 'direct' },
        'hopin.com' => { regex: %r{#{http}#{subdomain}hopin.com/#{suffix}}, type: 'direct' }
      }
    end
  end
end
