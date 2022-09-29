# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class ManchesterUni < Xml
    PUBLIC = false
    NAME = 'Manchester University'
    DOMAINS = %w[events.manchester.ac.uk]

    def self.whitelist_pattern
      %r{^http(s)?://events.manchester.ac.uk/f3vf/calendar/.*}
    end

    def import_events_from(data)
      events = []

      data.xpath('//ns:event').each do |event|
        events << CalendarImporter::Events::ManchesterUniEvent.new(event)
      end

      events
    end
  end
end
