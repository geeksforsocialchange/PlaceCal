module Parsers
  class Xml
    def initialize(file)
      @file = file
    end

    def events
      @events = []
      xml = HTTParty.get(@file).body
      feed = Nokogiri::XML(xml)

      feed.css('show').each do |show|
        event_data = {}

        show.css('events').each do |event|
          @events << Events::XmlEvent.new(show)
        end

      end

      @events
    end
  end
end
