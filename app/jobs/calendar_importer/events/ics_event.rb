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

      text.to_s # .gsub(/\A(\n)+\z/, '').strip
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
      link = @event.url
      link ||= @event.custom_properties['x_google_conference']
      link ||= find_event_link

      link = link.first if link.is_a?(Array)
      link = link.to_s

      return if link.blank?

      # Then grab the first element of either the match object or the conference array
      # (The match object returns ICal Text, not a String, so we have to cast)
      # (We can't use .first here because the match object doesn't support it!)
      #
      online_address = OnlineAddress.find_or_create_by(url: link,
                                                       link_type: have_direct_url_to_stream?(link))
      online_address.id
    end

    private

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
        'meet.jit.si' => { regex: %r{#{http}#{subdomain}meet.jit.si/#{suffix}}, type: 'direct' },
        'meet.google.com' => { regex: %r{#{http}#{subdomain}meet.google.com/#{suffix}}, type: 'direct' },
        'zoom.us' => { regex: %r{#{http}#{subdomain}zoom.us/j/#{suffix}}, type: 'direct' }
      }
    end
  end
end
