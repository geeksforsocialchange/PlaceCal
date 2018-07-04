module Parsers
  class ManchesterUni < Xml
    def self.whitelist_pattern
      /http(s)?:\/\/events.manchester.ac.uk\/f3vf\/calendar\/.*/
    end

    def import_events_from(data)
      events = []

      data.xpath('//ns:event').each do |event|
        events << Events::ManchesterUniEvent.new(event)
      end

      events
    end

  end
end
