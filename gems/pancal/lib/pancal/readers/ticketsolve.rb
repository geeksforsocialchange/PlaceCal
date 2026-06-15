# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class Ticketsolve < Xml
      NAME = 'Ticket Solve'
      KEY = 'ticket-solve'
      DOMAINS = %w[*.ticketsolve.com].freeze

      def self.allowlist_pattern
        %r{^https?://([^.]*)\.ticketsolve\.com/?}
      end

      def import_events_from(data)
        @events = []

        data.css('show').each do |show|
          @events << Events::TicketsolveEvent.new(show)
        end

        @events
      end
    end
  end
end
