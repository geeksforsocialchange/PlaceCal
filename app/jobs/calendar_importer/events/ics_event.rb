# frozen_string_literal: true

module CalendarImporter::Events
  class IcsEvent < Base
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
      text = text.join(' ') if text.is_a?(Icalendar::Values::Array)

      text.to_s #.gsub(/\A(\n)+\z/, '').strip
    end

    def location
      @event.location.to_s
    end

    def rrule
      @event.rrule
    end

    def last_updated
      @event.last_modified.to_s
    end

    def recurring_event?
      rrule.present?
    end

    def occurrences_between(from, to)
      @event.occurrences_between(from, to)
    end

    def online_event?
      # Either return the google conference value, or find the link in the description
      link = @event.custom_properties.fetch 'x_google_conference', nil
      link ||= find_event_link

      return unless link

      # Then grab the first element of either the match object or the conference array
      # (The match object returns ICal Text, not a String, so we have to cast)
      # (We can't use .first here because the match object doesn't support it!)
      #
      online_address = OnlineAddress.find_or_create_by url: link[0].to_s,
                                                       is_stream: is_stream_event(link[0].to_s)
      online_address.id
    end

    private

    def is_stream_event(link)
      # All the other ICS links we grab are videoconferencing URLs
      !link.include? 'facebook.com'
    end

    def find_event_link
      regex = event_link_regex
      regex.match description
    end

    def event_link_regex
      http = %r{(http(s)?://)?}        # - https:// or http:// or nothing
      alphanum = %r{[A-Za-z0-9]+}      # - alphanumeric strings
      subdomain = %r{(#{alphanum}\.)?} # - matches the www. or us04web in the zoom link
      suffix = %r{[^\s<"]+}            # - matches until we see a whitespace character,
                                       #   an angle bracket, or a quote (thanks html)

      # We deal with the following strings:
      #   meet.jit.si/foobarbaz
      #   meet.google.com/kbv-byuf-cvq
      #   facebook.com/events/(really long url)
      #   us04web.zoom.us/j/(really long url)
      #   zoom.us/j/(really long url)
      # We also deal with strings like
      #   <a href="(event url)">
      #   <p>(event url)</p>

      links = {
        'jitsi': %r{#{http}#{subdomain}meet.jit.si/#{suffix}},
        'meets': %r{#{http}#{subdomain}meet.google.com/#{suffix}},
        'facebook': %r{#{http}#{subdomain}facebook.com/events/#{suffix}},
        'zoom': %r{#{http}#{subdomain}zoom.us/j/#{suffix}}
      }

      Regexp.union links.values
    end
  end
end
