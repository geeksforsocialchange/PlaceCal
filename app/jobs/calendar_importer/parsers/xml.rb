# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Xml < Base
    def download_calendar
      # xml = HTTParty.get(@url, follow_redirects: true).body
      response_body = Base.read_http_source(@url)

      Nokogiri::XML response_body
    end
  end
end
