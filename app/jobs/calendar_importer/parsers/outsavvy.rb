# frozen_string_literal: true

module CalendarImporter::Parsers
  class Outsavvy < Base
    NAME = 'OutSavvy'
    KEY = 'outsavvy'
    DOMAINS = %w[outsavvy.com].freeze

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

      'logo_url' => { '@id' => 'http://schema.org/logo', '@type' => '@id' },
      'image_url' => { '@id' => 'http://schema.org/image', '@type' => '@id' },
      'url' => { '@id' => 'http://schema.org/url', '@type' => '@id' }
    }.freeze

    def self.allowlist_pattern
      %r{^https://www\.outsavvy\.com/organiser/[^/]*/?$}
    end

    # Get event URLs from an organiser page

    def extract_event_urls(organiser_url)
      response_body = Base.read_http_source(organiser_url)

      doc = Nokogiri::HTML(response_body)

      live_events = doc.xpath('//div[@id="live_events"]/div[@id="eventscontent"]/div/*')

      live_events.map { |event| event.xpath('./div/a').attr('href').value }
    end

    def download_calendar
      extract_event_urls(@url).flat_map do |event_url|
        response_body = Base.read_http_source(event_url)

        doc = Nokogiri::HTML(response_body)
        data_nodes = doc.xpath('//script[@type="application/ld+json"]')

        data_nodes.reduce([]) do |out, node|
          json = Base.safely_parse_json(node.inner_html)
          expanded = JSON::LD::API.expand(json)
          compact = JSON::LD::API.compact(expanded, CONTEXT)
          out.append compact
        end
      end
    end

    def import_events_from(data)
      consumer = CalendarImporter::Parsers::LdJson::EventConsumer.new
      consumer.consume data
      consumer.validate_events
      consumer.events
    end
  end
end
