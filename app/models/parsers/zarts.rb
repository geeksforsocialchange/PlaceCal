module Parsers
  class Zarts < Xml
    def initialize(file)
      @file = file
    end

    def self.whitelist_pattern
      /https:\/\/z-arts.ticketsolve.com\.*/
    end

    end

    def events
      @events = []
      download_calendar.css('show').each do |show|
        @events << Events::ZartsEvent.new(show)
      end

      @events
    end
  end
end
