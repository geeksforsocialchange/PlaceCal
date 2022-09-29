# frozen_string_literal: true

module CalendarImporter::Events
  class Base
    ALLOWED_TAGS = %w[p a strong b em i ul ol li blockquote h3 h4 h5 h6 br]

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

      clean_text = sanitize_invalid_char(input)
      input_mode = 'markdown'

      doc = Nokogiri::HTML.fragment(clean_text)
      if doc.css('*').length > 0
        input_mode = 'html'
        # looks like HTML to us

        # if doc.errors.any? # this could be useful?
        #  puts 'errors found:'
        #  puts doc.errors
        #  return ''
        # end

        doc.css('h1', 'h2').each { |header| header.name = 'h3' }

        if footer.present?
          doc << '<br/><br/>'
          doc << footer
        end

        body_text = doc.serialize
        clean_text = ActionController::Base.helpers.sanitize(body_text, tags: ALLOWED_TAGS)
      end

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
      postal = location.match(Address::POSTCODE_REGEX).try(:[], 0)
      if postal.blank?
        postal = /M[1-9]{2}(?:\s)?(?:[1-9])?/.match(location).try(:[], 0)
      end # check for instances of M14 or M15 4 or whatever madness they've come up with

      # TODO? Remove? This will currently do nothing because postcodes.io only
      # works on postcodes and we have established that a postcode does not
      # exist in the current address.
      # if postal.blank?
      #   # See if Google returns a more informative address
      #   results = Geocoder.search(location)
      #   if results.first
      #     formatted_address = results.first.data['formatted_address']
      #
      #     postal = Address::POSTCODE_REGEX.match(formatted_address).try(:[], 0)
      #   end
      # end

      postal
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
