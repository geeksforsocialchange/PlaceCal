# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class DiceFm < LdJson
    NAME = 'Dice FM (LD+JSON)'
    KEY = 'dice-fm'
    DOMAINS = %w[dice.fm].freeze

    def self.whitelist_pattern
      %r{^https://dice\.fm/venue/*}
    end

    def initialize(calendar, options = {})
      options[:consumer_helper] = EventConsumer
      super calendar, options
    end

    module EventConsumer
      def consume_place(data)
        Rails.logger.debug 'consume_place'
        consume data['event']
      end
    end
  end
end
