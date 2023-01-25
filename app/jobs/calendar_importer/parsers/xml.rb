# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Xml < Base
    include CalendarImporter::Exceptions

    def download_calendar
      parse_xml Base.read_http_source(@url)
    end

    def parse_xml(xml)
      Nokogiri::XML xml
    end
  end
end
