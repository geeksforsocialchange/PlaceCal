# frozen_string_literal: true

module CalendarImporter::Events
  class IcsEvent < Base
    imports title: 'SUMMARY', description: 'DESCRIPTION', start_time: 'DTSTART', end_time: 'DTEND', repeats: 'RRULE',
            location: 'LOCATION', webpage: %w[URL LOCATION],
            online_link: %w[X-GOOGLE-CONFERENCE X-MICROSOFT-SKYPETEAMSMEETINGURL X-MICROSOFT-ONLINEMEETINGCONFLINK
                            X-ZOOM-MEETING-URL LOCATION DESCRIPTION],
            status: 'STATUS', image: %w[IMAGE ATTACH], source_categories: 'CATEGORIES',
            source_organiser: 'ORGANIZER',
            ticket_url: nil, price: nil, sold_out: nil

    # Domains that indicate a direct online meeting link
    ONLINE_MEETING_DOMAINS = OnlineAddress::MEETING_DOMAINS

    # Calendar custom properties that may contain online meeting URLs
    ONLINE_MEETING_PROPERTIES = %w[
      x_google_conference
      x_microsoft_skypeteamsmeetingurl
      x_microsoft_onlinemeetingconflink
      x_zoom_meeting_url
    ].freeze

    OVERRIDABLE_FIELDS = %i[summary description publisher_url].freeze

    def initialize(event, start_date, end_date, overrides: [])
      @event = event
      @dtstart = start_date
      @dtend = end_date
      @overrides = overrides
    end

    attr_reader :dtstart, :dtend, :overrides

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

    # A CATEGORIES line with several values parses to an Icalendar array, one with a single value to a Text
    def source_categories
      @event.categories.flat_map { |line| line.respond_to?(:to_a) ? line.to_a : line }.map(&:to_s)
    end

    def source_organiser
      organizer = @event.organizer
      Array(organizer.ical_params['cn']).first if organizer
    end

    # Google Calendar attaches Drive's viewer page; this form gives the file itself when it's shared publicly
    DRIVE_FILE = %r{\Ahttps://drive\.google\.com/(?:open\?id=|file/d/)([\w-]+)}

    # RFC 7986's IMAGE, or the first attachment that is an image, as WordPress's The Events Calendar and Google Calendar send
    def image_url
      image = Array(@event.image).first || @event.attach.find { |attachment| image_attachment?(attachment) }
      return unless image.is_a?(Icalendar::Values::Uri) || image.is_a?(Icalendar::Values::Text)

      drive_id = image.to_s[DRIVE_FILE, 1]
      drive_id ? "https://drive.google.com/uc?export=download&id=#{drive_id}" : image.to_s
    end

    def recurring_event?
      rrule.present?
    end

    def occurrences_between(from, to)
      occurrences = @event.occurrences_between(from, to).map do |occurrence|
        Occurrence.new(start_time: occurrence.start_time, end_time: occurrence.end_time)
      end
      return occurrences if overrides.empty?

      overridden = overrides.map(&:recurrence_start)
      window = Icalendar::Recurrence::TimeUtil.to_time(from)..Icalendar::Recurrence::TimeUtil.to_time(to)

      occurrences.reject { |occurrence| overridden.include?(occurrence.start_time.to_i) } +
        overrides.reject(&:private?).map(&:overriding_occurrence).select { |occurrence| window.cover?(occurrence.start_time) }
    end

    # An overriding event's fields replace the series' on its date
    def attributes_for(occurrence)
      return attributes unless occurrence.override

      override = occurrence.override
      attributes.merge(override.attributes.slice(*OVERRIDABLE_FIELDS).compact_blank, status: override.status)
    end

    def recurrence_start
      Icalendar::Recurrence::TimeUtil.to_time(@event.recurrence_id).to_i
    end

    # iCal has no postponed status, only CANCELLED, TENTATIVE and CONFIRMED
    def status
      @event.status.to_s.casecmp?('CANCELLED') ? 'cancelled' : 'scheduled'
    end

    def overriding_occurrence
      Occurrence.new(start_time: @event.schedule.start_time.utc, end_time: @event.schedule.end_time.utc, override: self)
    end

    # The iCal URL property links to the event's webpage, not a meeting; so does a LOCATION
    # that is a link anywhere but a meeting host, such as a ticket page.
    def publisher_url
      url = @event.url
      url = url.first if url.is_a?(Array)
      url.to_s.presence || location_webpage
    end

    def online_event_id
      link = online_meeting_custom_property
      link ||= meeting_location
      link ||= find_event_link_in_description

      link = link.first if link.is_a?(Array)
      link = link.to_s

      return if link.blank?

      # Every link found here is a way to join, even on a host we don't list
      online_address = OnlineAddress.find_or_create_by(url: link, link_type: 'direct')
      online_address.id
    end

    private

    def online_meeting_custom_property
      props = @event.custom_properties
      ONLINE_MEETING_PROPERTIES.lazy.filter_map { |key| props[key] }.first
    end

    def location_link
      uri = URI.parse(location.strip)
      uri.to_s if uri.scheme&.match?(/\Ahttps?\z/i) && uri.host.present?
    rescue URI::InvalidURIError
      nil
    end

    def meeting_location
      location_link if OnlineAddress.meeting?(location_link)
    end

    def location_webpage
      location_link unless OnlineAddress.meeting?(location_link)
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

    def image_attachment?(attachment)
      params = attachment.ical_params
      Array(params['fmttype']).first.to_s.start_with?('image/') ||
        [Array(params['filename']).first, attachment.to_s].any? { |name| name.to_s.match?(/\.(jpe?g|png|gif|webp)(\?|\z)/i) }
    end
  end
end
