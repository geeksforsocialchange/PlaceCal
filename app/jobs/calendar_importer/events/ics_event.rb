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
      online_address = OnlineAddress.find_or_create_by(url: link[0].to_s,
                                                       link_type: have_direct_url_to_stream?(link[0].to_s))
      online_address.id
    end

    private

    def have_direct_url_to_stream?(link)
      # Oh my god why is ruby's iteration stuff so annoying
      # also TODO: find a different name than "value"
      domain = event_link_types.keys.find(proc { nil }) { |domain| link.include?(domain) }

      return event_link_types[domain][:type] if domain

      # Because there is a type for each URL handled, this should never occur
      # However, in the future, those URLs will be edited, so we should guard against this
      raise MissingTypeForURL, "Type (direct/indirect) missing for URL #{link}"
    end

    def find_event_link
      link_regexes = event_link_types.values.map { |v| v[:regex] }
      regex = Regexp.union link_regexes

      regex.match description
    end

    def event_link_types
      http = %r{(http(s)?://)?}        # - https:// or http:// or nothing
      alphanum = %r{[A-Za-z0-9]+}      # - alphanumeric strings
      subdomain = %r{(#{alphanum}\.)?} # - matches the www. or us04web in the zoom link
      suffix = %r{[^\s<"]+}            # - matches until we see a whitespace character,
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
        'meet.jit.si' =>     { regex: %r{#{http}#{subdomain}meet.jit.si/#{suffix}}, type: 'direct' },
        'meet.google.com' => { regex: %r{#{http}#{subdomain}meet.google.com/#{suffix}}, type: 'direct' },
        'zoom.us' =>         { regex: %r{#{http}#{subdomain}zoom.us/j/#{suffix}}, type: 'direct' }
      }
    end
  end
end
