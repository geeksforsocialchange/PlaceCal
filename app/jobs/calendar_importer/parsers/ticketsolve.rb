# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to CalendarImporter::CalendarImporter::PARSERS.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Ticketsolve < Xml
    NAME = 'Ticket Solve'
    KEY = 'ticket-solve'
    DOMAINS = %w[*.ticketsolve.com].freeze

    def self.event_class = CalendarImporter::Events::TicketsolveEvent

    def self.allowlist_pattern
      %r{^https?://([^.]*)\.ticketsolve\.com/?}
    end

    def import_events_from(data)
      @events = []

      data.css('show').each do |show|
        @events << self.class.event_class.new(show)
      end

      @events
    end
  end
end
