# frozen_string_literal: true

module CalendarImporter::Events
  class Base
    ALLOWED_TAGS = %w[p a strong b em i ul ol li blockquote h3 h4 h5 h6 br].freeze

    Dates = Struct.new(:start_time, :end_time, :status)

    def initialize(event)
      @event = event
    end

    attr_accessor :place_id,
                  :address_id,
                  :partner_id,
                  :online_address_id

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
    def html_sanitize(input)
      input = input.to_s.strip
      return '' if input.blank?

      # attempt to get rid of broken UTF-8
      clean_text = sanitize_invalid_char(input)
      input_mode = 'markdown'

      # do we have HTML? yeah let's get rid of that
      doc = Nokogiri::HTML.fragment(clean_text)
      if doc.css('*').length.positive?
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
        clean_text = ActionController::Base.helpers.sanitize(body_text, tags: ALLOWED_TAGS)
      end

      # convert HTML tags into markdown kramdown
      Kramdown::Document.new(clean_text, input: input_mode).to_kramdown.strip
    end

    def attributes
      { uid: uid&.strip,
        summary: sanitize_invalid_char(summary),
        description: html_sanitize(description),
        raw_location_from_source: location&.strip,
        rrule: rrule,
        place_id: place_id,
        address_id: address_id,
        partner_id: partner_id,
        publisher_url: publisher_url,
        online_address_id: online_address_id }
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
                    &.to_s
    end

    def ip_class
      @event&.ip_class if @event.respond_to?(:ip_class)
    end

    def private?
      ip_class&.casecmp('private')&.zero? || description&.include?('#placecal-ignore')
    end

    def online_event?
      # TODO: Put in default here
      nil
    end
  end
end
