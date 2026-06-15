# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class ManchesterUni < Xml
      PUBLIC = false
      NAME = 'Manchester University'
      DOMAINS = %w[events.manchester.ac.uk].freeze

      def self.allowlist_pattern
        %r{^https?://events\.manchester\.ac\.uk/f3vf/calendar/.*}
      end

      def import_events_from(data)
        data.xpath('//ns:event').map do |event|
          Events::ManchesterUniEvent.new(event)
        end
      end
    end
  end
end
