module Parsers
  class ManchesterUni < DefaultParser
    def initialize(file)
      @file = file
    end

    def self.whitelist_pattern
      /http:\/\/events.manchester.ac.uk\/f3vf\/calendar\/.*/
    end

    def events
      @events = []
      xml = HTTParty.get(@file, follow_redirects: true).body
      feed = Nokogiri::XML(xml)

      feed.css('ns:event').each do |show|
        @events << Events::ManchesterUniEvent.new(show)
      end

      @events
    end
  end
end
