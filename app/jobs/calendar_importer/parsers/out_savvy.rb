# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class OutSavvy < LdJson
    NAME = 'OutSavvy (LD+JSON)'
    KEY = 'out-savvy'
    DOMAINS = %w[www.outsavvy.com].freeze

    def self.whitelist_pattern
      %r{^https://(www\.)?outsavvy\.com/organiser/.*}
    end
  end
end
