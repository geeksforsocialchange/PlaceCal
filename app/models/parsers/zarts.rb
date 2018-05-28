module Parsers
  class Zarts < DefaultParser
    def initialize(file)
      @file = file
    end

    def self.whitelist_pattern
      /https:\/\/z-arts.ticketsolve.com\.*/
    end

    end

    def events
      @events = []
      xml = HTTParty.get(@file, follow_redirects: true).body
      feed = Nokogiri::XML(xml)

      feed.css('show').each do |show|
        @events << Events::ZartsEvent.new(show)
      end

      @events
    end
  end
end
