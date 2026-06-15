# frozen_string_literal: true

# In order for a reader to be recognized, it must be added
# to the READERS constant list in lib/pancal/detector.rb.
# Parent reader classes should not be added.

module PanCal
  module Readers
    class Base
      PUBLIC = true
      NAME = ''
      KEY = ''

      def self.requires_api_token?
        false
      end

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

      def self.handles_url?(source)
        source.url =~ allowlist_pattern
      end

      def initialize(source, options = {})
        @source = source
        @url = source.url
        @logger = options[:logger] || PanCal.logger
      end

      attr_reader :source, :logger

      # Downloads the feed and parses it into canonical events.
      # When the feed checksum matches source.last_checksum and force is
      # false, parsing is skipped and the result carries no events. PanCal
      # never persists the checksum — the caller does, from the result.
      def read(force: false)
        data = download_calendar
        checksum = digest(data)
        changed = @source.last_checksum != checksum

        events = force || changed ? import_events_from(data) : []

        Result.new(events: events,
                   checksum: checksum,
                   changed: changed,
                   reader_key: self.class::KEY)
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
        raise InvalidResponse.new('Source responded with missing JSON', code: :missing_data) if string.blank?

        JSON.parse string.to_s
      rescue JSON::JSONError => e
        raise InvalidResponse.new("Source responded with invalid JSON (#{e})", code: :invalid_json)
      end

      # Perform a HTTP GET on the remote URL and return the response body
      #  if successful. If the URL is invalid or the response from the URL
      #  is not 200 (even following redirects) then raise the correct
      #  exception with an appropriate message
      def self.read_http_source(url, follow_redirects: true)
        # webcal:// is just https:// with a different scheme — normalize before fetching
        url = url.sub(%r{\Awebcal://}i, 'https://')

        # User-Agent is currently set to make Resident Advisor happy, but this is also more "honest".
        # It may be this method needs per-vendor headers
        response = HTTParty.get(url, follow_redirects: follow_redirects, headers: { 'User-Agent': 'Httparty' })
        return response.body if response.success?

        case response.code
        when 403
          raise InaccessibleFeed.new('The source URL is not public or is missing',
                                     code: :forbidden, http_status: 403)
        when 404
          raise InaccessibleFeed.new('The source URL could not be found',
                                     code: :not_found, http_status: 404)
        else
          raise InaccessibleFeed.new("The source URL could not be read (code=#{response.code})",
                                     code: :unreadable, http_status: response.code)
        end
      rescue HTTParty::ResponseError => e
        raise InaccessibleFeed.new("The source URL could not be resolved (#{e})", code: :unresolvable)
      rescue SocketError => e
        raise InaccessibleFeed.new("There was a socket error (#{e})", code: :socket_error)
      rescue Net::ReadTimeout, Net::OpenTimeout, OpenSSL::SSL::SSLError => e
        # Slow/unreachable feeds and TLS negotiation failures are expected when
        # scraping third-party sources. Treat them as an unreachable source rather
        # than letting them bubble up as unhandled exceptions (see issue #3100).
        PanCal.logger.warn("Calendar source unreachable for #{url}: #{e.class} (#{e.message})")
        raise InaccessibleFeed.new('The source URL did not respond in time', code: :unreachable)
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
end
