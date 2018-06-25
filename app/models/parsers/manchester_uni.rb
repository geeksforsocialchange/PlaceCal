module Parsers
  class ManchesterUni < Xml
    def initialize(file)
      @file = file
    end

    def self.whitelist_pattern
      /http:\/\/events.manchester.ac.uk\/f3vf\/calendar\/.*/
    end

    def events
      @events = []

      download_calendar.xpath('//ns:event').each do |event|
        @events << Events::ManchesterUniEvent.new(event)
      end

      @events
    end
  end
end
