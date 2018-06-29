module Parsers
  class ManchesterUni < Xml
    def self.whitelist_pattern
      /http:\/\/events.manchester.ac.uk\/f3vf\/calendar\/.*/
    end

    def import_events_from(data)
      events = []

      data.xpath('//ns:event').each do |event|
        puts event.inspect
        events << Events::ManchesterUniEvent.new(event)
      end

      events
    end

  end
end
