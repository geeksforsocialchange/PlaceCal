# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Ticketsolve < Xml
    NAME = 'Ticket Solve'
    KEY = 'ticket-solve'
    DOMAINS = %w[*.ticketsolve.com].freeze

    URL_PATTERNS = [
      { pattern: '^https?://([^.]*)\.ticketsolve\.com/?', flags: '' }
    ].freeze

    def import_events_from(data)
      @events = []

      data.css('show').each do |show|
        @events << CalendarImporter::Events::TicketsolveEvent.new(show)
      end

      @events
    end
  end
end
