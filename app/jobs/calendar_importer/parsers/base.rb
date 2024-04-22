# frozen_string_literal: true

# In order for a parser to be recognized, it must be added
# to the PARSERS constant list in app/models/calendar_parser.rb.
# Parent parser classes should not be added.

module CalendarImporter::Parsers
  class Base
    include CalendarImporter::Exceptions

    PUBLIC = true
    NAME = ''
    KEY = ''
    Output = Struct.new(:events, :checksum)

    def self.handles_url?(calendar)
      calendar.source =~ allowlist_pattern
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

      ## record if checksum has changed since last time we interacted with it.
      ## if download_calendar fails it should raise an exception so this code won't run
      if @calendar.last_checksum != checksum
        @calendar.update!(
          last_checksum: checksum,
          checksum_updated_at: DateTime.current
        )
      end

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

    def self.safely_parse_json(string)
      raise InvalidResponse, 'Source responded with missing JSON' if string.blank?

      JSON.parse string.to_s
    rescue JSON::JSONError => e
      raise InvalidResponse, "Source responded with invalid JSON (#{e})"
    end

    # Perform a HTTP GET on the remote URL and return the response body
    #  if successful. If the URL is invalid or the response from the URL
    #  is not 200 (even following redirects) then raise the correct
    #  exception with an appropriate message
    def self.read_http_source(url, follow_redirects: true)
      response = HTTParty.get(url, follow_redirects: follow_redirects)
      return response.body if response.success?

      msg = "The source URL could not be read (code=#{response.code})"
      raise InaccessibleFeed, msg
    rescue HTTParty::ResponseError => e
      raise InaccessibleFeed, "The source URL could not be resolved (#{e})"
    rescue SocketError => e
      raise InaccessibleFeed, "There was a socket error (#{e})"
    end
  end
end
