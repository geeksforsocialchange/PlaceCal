# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Xml < Base
    include CalendarImporter::Exceptions

    def download_calendar
      # xml = HTTParty.get(@url, follow_redirects: true).body
      parse_xml Base.read_http_source(@url)
    end

    def parse_xml(response_body)
      raise BadFeedResponse, 'The XML response was empty' if response_body.blank?

      Nokogiri::XML(response_body).tap do |document|
        if document.errors.any?
          # msg = "The XML response could not be parsed (#{document.errors.join(', ')})"
          # raise BadFeedResponse, msg

          raise BadFeedResponse, 'The XML response could not be parsed'
        end
      end
    end
  end
end
