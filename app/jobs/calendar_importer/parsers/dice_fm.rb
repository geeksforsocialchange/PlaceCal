# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class DiceFm < LdJson
    NAME = 'Dice FM'
    KEY = 'dice-fm'
    DOMAINS = %w[dice.fm].freeze

    def self.whitelist_pattern
      %r{^https://dice\.fm/venue/*}
    end
  end
end
