# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class OutSavvy < LdJson
    NAME = 'OutSavvy'
    KEY = 'out-savvy'
    DOMAINS = %w[www.outsavvy.com].freeze

    def self.whitelist_pattern
      %r{^https://(www\.)?outsavvy\.com/organiser/.*}
    end

    def initialize(calendar, options)
      Rails.logger.debug 'OutSavvy#initialize'
      # options[:consumer_helper] = EventConsumer
      super calendar, options
    end

    # module EventConsumer
    #  def consume_place(data)
    #    puts 'consume_place'
    #    consume data['event']
    #  end
    # end
  end
end
