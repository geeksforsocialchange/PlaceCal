module Parsers
  class Xml
    def initialize(file)
      @file = file
    end

    def events
      @events = []
      xml = HTTParty.get(@file).body
      feed = Nokogiri::XML(xml)

      feed.css('show') do |show|
        events = show.css('events')

      end
    end
  end
end
