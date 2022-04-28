# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Base
    PUBLIC = true
    Output = Struct.new(:events, :checksum)

    def self.handles_url?(url)
      url =~ whitelist_pattern
    end

    def initialize(calendar, url, options={})
      @calendar = calendar
      @url = url
      @from = options.delete(:from)
      @to = options.delete(:to)
    end

    # Takes a calendar feed and imports it
    # Returns array of events
    #
    def calendar_to_events(skip_checksum=false)
      data   = download_calendar
      checksum = digest(data)

      if !skip_checksum && (@calendar.last_checksum == checksum)
        return Output.new([], checksum)
      end

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
  end
end
