# frozen_string_literal: true

module CalendarImporter::Parsers
  class LdJson < Base
    NAME = 'LD+JSON'
    KEY = 'ld-json'
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

      'logo_url' => { '@id' => 'http://schema.org/logo', '@type' => '@id' },
      'image_url' => { '@id' => 'http://schema.org/image', '@type' => '@id' },
      'url' => { '@id' => 'http://schema.org/url', '@type' => '@id' }
    }.freeze

    class EventConsumer
      TYPE_DISPATCH = {
        'Event' => :consume_event,
        'BusinessEvent' => :consume_event,
        'ChildrensEvent' => :consume_event,
        'ComedyEvent' => :consume_event,
        'CourseInstance' => :consume_event,
        'DanceEvent' => :consume_event,
        'DeliveryEvent' => :consume_event,
        'EducationEvent' => :consume_event,
        'EventSeries' => :consume_event,
        'ExhibitionEvent' => :consume_event,
        'Festival' => :consume_event,
        'FoodEvent' => :consume_event,
        'Hackathon' => :consume_event,
        'LiteraryEvent' => :consume_event,
        'MusicEvent' => :consume_event,
        'PublicationEvent' => :consume_event,
        'SaleEvent' => :consume_event,
        'ScreeningEvent' => :consume_event,
        'SocialEvent' => :consume_event,
        'SportsEvent' => :consume_event,
        'TheaterEvent' => :consume_event,
        'VisualArtsEvent' => :consume_event,
        'Place' => :consume_place,
        'Brand' => :consume_noop,
        'WebSite' => :consume_noop
      }.freeze

      def consume_noop(data); end

      def consume_place(data)
        # puts 'Place'
        consume data['event']
      end

      def consume_event(data)
        # puts 'Event'
        events << ::CalendarImporter::Events::LinkedDataEvent.new(data)
      end

      def consume(data)
        if data.is_a?(Array)
          data.each do |datum|
            consume datum
          end
          return
        end

        if data.is_a?(Hash) # rubocop:disable Style/GuardClause
          type = data['@type']
          # puts type
          return unless type

          short_type = (type =~ %r{^http://schema.org/(\w+)$}) && Regexp.last_match(1)
          return unless short_type

          # puts short_type

          dispatch_to = TYPE_DISPATCH[short_type]
          # puts dispatch_to
          if dispatch_to
            send dispatch_to, data
          else
            Rails.logger.debug { "uknown type '#{type}'" }
          end
          nil
        end
      end

      def validate_events
        events.select!(&:valid?)
      end

      def events
        @events ||= []
      end
    end

    def download_calendar
      response = HTTParty.get(@url)
      return [] unless response.success?

      doc = Nokogiri::HTML(response.body)
      data_nodes = doc.xpath('//script[@type="application/ld+json"]')

      data_nodes.reduce([]) do |out, node|
        json = JSON.parse(node.inner_html)
        expanded = JSON::LD::API.expand(json)
        compact = JSON::LD::API.compact(expanded, CONTEXT)
        out.append compact
      end
    end

    def import_events_from(data)
      consumer = EventConsumer.new
      consumer.consume data
      consumer.validate_events
      consumer.events
    end
  end
end
