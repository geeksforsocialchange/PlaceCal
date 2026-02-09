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

    def self.skip_source_validation?
      false
    end
    Output = Struct.new(:events, :checksum_changed)

    CONTEXT = {
      'geo' => 'http://schema.org/geo',
      'location' => 'http://schema.org/location',
      'description' => 'http://schema.org/description',
      'latitude' => 'http://schema.org/latitude',
      'longitude' => 'http://schema.org/longitude',
      'address' => 'http://schema.org/address',
      'end_date' => 'http://schema.org/endDate',
      'start_date' => 'http://schema.org/startDate',
      'organiser' => 'http://schema.org/organizer',
      'event' => 'http://schema.org/event',
      'name' => 'http://schema.org/name',
      'street_address' => 'http://schema.org/streetAddress',
      'address_locality' => 'http://schema.org/addressLocality',
      'address_region' => 'http://schema.org/addressRegion',
      'postal_code' => 'http://schema.org/postalCode',
      'address_country' => 'http://schema.org/addressCountry',

      'logo_url' => { '@id' => 'http://schema.org/logo', '@type' => '@id' },
      'image_url' => { '@id' => 'http://schema.org/image', '@type' => '@id' },
      'url' => { '@id' => 'http://schema.org/url', '@type' => '@id' }
    }.freeze

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
      checksum_changed = @calendar.last_checksum != checksum
      ## record if checksum has changed since last time we interacted with it.
      ## if download_calendar fails it should raise an exception so this code won't run
      @calendar.flag_checksum_change!(checksum) if checksum_changed
      return Output.new([], checksum) if !@force_import && !checksum_changed

      Output.new(import_events_from(data), checksum_changed)
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
      # User-Agent is currently set to make Resident Advisor happy, but this is also more "honest".
      # It may be this method needs per-vendor headers
      response = HTTParty.get(url, follow_redirects: follow_redirects, headers: { 'User-Agent': 'Httparty' })
      return response.body if response.success?

      msg = case response.code
            when 403
              I18n.t('admin.calendars.wizard.source.forbidden')
            when 404
              I18n.t('admin.calendars.wizard.source.not_found')
            else
              I18n.t('admin.calendars.wizard.source.unreadable', code: response.code)
            end
      raise InaccessibleFeed, msg
    rescue HTTParty::ResponseError => e
      raise InaccessibleFeed, "The source URL could not be resolved (#{e})"
    rescue SocketError => e
      raise InaccessibleFeed, "There was a socket error (#{e})"
    end

    def self.parse_ld_json(url)
      response_body = read_http_source(url)

      doc = Nokogiri::HTML(response_body)
      data_nodes = doc.xpath('//script[@type="application/ld+json"]')

      data_nodes.reduce([]) do |out, node|
        json = safely_parse_json(node.inner_html)
        expanded = JSON::LD::API.expand(json)
        compact = JSON::LD::API.compact(expanded, CONTEXT)
        out.append compact
      end
    end
  end
end
