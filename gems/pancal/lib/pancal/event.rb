# frozen_string_literal: true

module PanCal
  # Canonical event contract. Every reader returns events that implement this
  # interface; the source-specific subclasses in PanCal::Events are private
  # mapping code and should not be referenced directly by callers.
  #
  # PanCal events carry no persistence concerns: online meeting links are
  # reported as a plain URL string (online_meeting_url) and location as a raw
  # string + extracted UK postcode. Resolving those against a database is the
  # caller's job.
  class Event
    ALLOWED_TAGS = %w[p a strong b em i ul ol li blockquote h3 h4 h5 h6 br].freeze

    # Domains that indicate a direct online meeting/streaming link, as
    # opposed to an event webpage. Public so callers can classify
    # online_meeting_url values.
    ONLINE_MEETING_DOMAINS = %w[
      meet.jit.si
      meet.google.com
      zoom.us
      teams.microsoft.com
      teams.live.com
      webex.com
      gotomeet.me
      gotomeeting.com
      discord.gg
      discord.com
      youtube.com
      youtu.be
      twitch.tv
      vimeo.com
      facebook.com
      fb.watch
      instagram.com
      linkedin.com
      crowdcast.io
      streamyard.com
      hopin.com
    ].freeze

    Occurrence = Struct.new(:start_time, :end_time, :status)

    def initialize(event)
      @event = event
    end

    def rrule
      nil
    end

    def sanitize_invalid_char(input)
      input.encode('utf-8', invalid: :replace, undef: :replace, replace: '')
    end

    # Convert h1 and h2 to h3
    # Strip out all shady tags
    # Convert all html to markdown
    def html_sanitize(input, as_plaintext: false)
      input = input.to_s.strip
      return '' if input.blank?

      # attempt to get rid of broken UTF-8
      clean_text = sanitize_invalid_char(input)
      input_mode = 'markdown'

      # do we have HTML? yeah let's get rid of that
      doc = Nokogiri::HTML.fragment(clean_text)

      if as_plaintext
        doc.text
      else
        tags = doc.css('*')

        if tags.present?
          input_mode = 'html'
          # looks like HTML to us

          doc.css('h1', 'h2').each { |header| header.name = 'h3' }

          # if we get HTML then remove all the attributes from all of
          # the tags so it doesn't interfere with the kramdown step
          doc.css('*').each do |tag|
            # rubocop:disable Style/HashEachMethods
            tag.keys.each do |attribute_name|
              next if tag.name == 'a' && attribute_name == 'href'

              tag.remove_attribute attribute_name
            end
            # rubocop:enable Style/HashEachMethods
          end

          if footer.present?
            doc << '<br/><br/>'
            doc << footer
          end

          body_text = doc.serialize
          clean_text = self.class.html_sanitizer.sanitize(body_text, tags: ALLOWED_TAGS)
        end

        Kramdown::Document.new(clean_text, input: input_mode).to_kramdown.strip
      end
    end

    # Same sanitizer ActionView's `sanitize` helper uses, minus Rails:
    # rails-html-sanitizer is a standalone gem
    def self.html_sanitizer
      @html_sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end

    def attributes
      { uid: uid&.strip,
        summary: html_sanitize(summary, as_plaintext: true),
        description: html_sanitize(description),
        raw_location_from_source: location&.strip,
        rrule: rrule,
        publisher_url: publisher_url }
    end

    def footer; end

    def publisher_url; end

    def has_location?
      location.present?
    end

    def recurring_event?
      false
    end

    def postcode
      location_parts = location.split(/[\s,]+/)

      location_parts.each_cons(2) do |location_part_pair|
        ukpc = UKPostcode.parse(location_part_pair.join(' '))

        return ukpc.to_s if ukpc.full_valid?
      end

      location_parts.map { |location_part| UKPostcode.parse(location_part) }
                    .find(&:full_valid?)
                    .to_s
    end

    def ip_class
      @event&.ip_class if @event.respond_to?(:ip_class)
    end

    def private?
      ip_class&.casecmp('private')&.zero? || description&.include?('#placecal-ignore')
    end

    # URL string for an online meeting/stream, or nil. PanCal only reports
    # the URL; persisting it is the caller's concern.
    def online_meeting_url; end
  end
end
