module Parsers
  class Zarts < Xml

    def self.whitelist_pattern
      /https:\/\/z-arts.ticketsolve.com\.*/
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
