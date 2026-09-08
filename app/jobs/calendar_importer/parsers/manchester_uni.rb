# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class ManchesterUni < Xml
    PUBLIC = false
    NAME = 'Manchester University'
    DOMAINS = %w[events.manchester.ac.uk].freeze

    URL_PATTERNS = [
      { pattern: '^https?://events\.manchester\.ac\.uk/f3vf/calendar/.*', flags: '' }
    ].freeze

    def import_events_from(data)
      events = data.xpath('//ns:event').map do |event|
        CalendarImporter::Events::ManchesterUniEvent.new(event)
      end
    end
  end
end
