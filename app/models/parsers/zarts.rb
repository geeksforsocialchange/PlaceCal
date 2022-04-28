# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module Parsers
  class Zarts < Xml

    def self.whitelist_pattern
      /http(s)?:\/\/z-arts.ticketsolve.com\.*/
    end

    def import_events_from(data)
      @events = []

      data.css('show').each do |show|
        @events << Events::ZartsEvent.new(show)
      end

      @events
    end

  end
end
