# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Base
    PUBLIC = true
    NAME = ''
    KEY = ''
    Output = Struct.new(:events, :checksum)

    def self.handles_url?(url)
      url =~ whitelist_pattern
    end

    def initialize(calendar, options = {})
      @calendar = calendar
      @url = calendar.source
      @from = options.delete(:from)
      @to = options.delete(:to)
      @force_import = options.delete(:force_import)
    end

    # Takes a calendar feed and imports it
    # Returns array of events
    #
    def calendar_to_events
      data = download_calendar
      checksum = digest(data)

      return Output.new([], checksum) if !@force_import && (@calendar.last_checksum == checksum)

      Output.new(import_events_from(data), checksum)
    end

    # @abstract Subclass is expect to implmement #download_calendar
    # @!method download_calendar
    #  Make http request to download calendar file from source

    # @abstract Subclass is expected to implement #import_events_from
    # @!method import_events_from
    #  Parse calendar file and wrap individual events in custom event class

    # Returns the unique MD5 Digest string of the calendar feed
    #
    def digest(data)
      Digest::MD5.hexdigest(data.to_s)
    end

    def safely_parse_json(string, default = nil)
      JSON.parse string
    rescue JSON::JSONError
      default
    end
  end
end
