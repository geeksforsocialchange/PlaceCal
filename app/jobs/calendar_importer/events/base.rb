# frozen_string_literal: true

module CalendarImporter::Events
  class Base
    ALLOWED_TAGS = %w[p a strong b em i ul ol li blockquote h3 h4 h5 h6 br].freeze

    # status fills are_spaces_available; override is an event whose fields replace the series' on this date
    Occurrence = Struct.new(:start_time, :end_time, :status, :override, keyword_init: true)

    # Each event field a source can fill, and the methods that can fill it
    FIELDS = {
      title: %i[summary], description: %i[description], start_time: %i[dtstart occurrences_between],
      end_time: %i[dtend occurrences_between], repeats: %i[rrule], location: %i[location],
      webpage: %i[publisher_url], online_link: %i[online_event_id], spaces_available: %i[occurrences_between],
      status: %i[status], image: %i[image_url], source_categories: %i[source_categories],
      source_organiser: %i[source_organiser]
    }.freeze

    class_attribute :field_map, instance_accessor: false, default: nil

    # Names the source field read for each of FIELDS, nil for one left blank; merges over the parent's
    def self.imports(**fields)
      unknown = fields.keys - FIELDS.keys
      raise ArgumentError, "Unknown event fields: #{unknown.join(', ')}" if unknown.any?

      self.field_map = (field_map || {}).merge(fields).freeze
    end

    def initialize(event)
      @event = event
    end

    def rrule
      nil
    end

    def sanitize_invalid_char(input)
      # input = I18n.transliterate(input)
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
      # Their contents are code, not copy; left in they become text (Squarespace sends inline <style>).
      doc.css('style, script, noscript, template').remove

      if as_plaintext
        doc.text
      else
        tags = doc.css('*')

        if tags.present?
          input_mode = 'html'
          # looks like HTML to us

          # if doc.errors.any? # this could be useful?
          #  puts 'errors found:'
          #  puts doc.errors
          #  return ''
          # end

          doc.css('h1', 'h2').each { |header| header.name = 'h3' }

          # if we get HTML then remove all the attributes from all of
          # the tags so it doesn't interfere with the kramdown step
          # Links around images are empty once the images are stripped
          doc.css('a').each { |link| link.remove if link.text.strip.empty? }

          doc.css('*').each do |tag|
            tag.keys.each do |attribute_name|
              next if tag.name == 'a' && attribute_name == 'href'

              tag.remove_attribute attribute_name
            end
          end

          body_text = doc.serialize
          # Indented page markup (Squarespace's galleries) would otherwise read as a Markdown code block
          clean_text = ActionController::Base.helpers.sanitize(body_text, tags: ALLOWED_TAGS).gsub(/^[ \t]+/, '')
        end

        Kramdown::Document.new(clean_text, input: input_mode).to_kramdown.strip
      end
    end

    def attributes
      { uid: uid&.strip,
        summary: html_sanitize(summary,
                               as_plaintext: true),
        description: html_sanitize(description),
        raw_location_from_source: location&.strip,
        rrule:,
        publisher_url:,
        source_categories: Base.clean_list(source_categories).presence,
        source_organiser: Base.clean_list(source_organiser).first,
        image_source_url: image_url.to_s.strip.presence,
        status: }
    end

    # One of Event::STATUSES; sources that can mark an event cancelled or postponed override it
    def status = 'scheduled'

    # Strings from the source, kept as text; they never become PlaceCal categories or partners
    def source_categories
      []
    end

    def source_organiser; end

    # Trimmed, unescaped and without blanks; a repeat in another case is dropped, keeping the first spelling
    def self.clean_list(values)
      Array(values).map { |value| CGI.unescapeHTML(value.to_s).squish }.compact_blank.uniq(&:downcase)
    end

    def attributes_for(occurrence)
      attributes.merge(are_spaces_available: occurrence.status)
    end

    def publisher_url; end

    def image_url; end

    def location?
      location.present?
    end

    def recurring_event?
      false
    end

    # @return [Array<Occurrence>] the event's one occurrence, for sources without repeats
    def occurrences_between(*)
      [Occurrence.new(start_time: dtstart, end_time: dtend)]
    end

    def postcode
      Base.postcode_in(location)
    end

    # @return [String] the first full UK postcode in the text, normalised, or "" if there is none
    def self.postcode_in(text)
      location_parts = text.to_s.split(/[\s,]+/)

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

    def online_event_id; end
  end
end
