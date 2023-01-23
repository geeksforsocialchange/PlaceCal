# frozen_string_literal: true

module CalendarImporter::Parsers
  class LdJson < Base
    NAME = 'LD+JSON'
    KEY = 'ld-json'

    DOMAINS = ['various'].freeze

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

    class EventConsumer
      TYPE_DISPATCH = {
        'Event' => :consume_event,
        'BusinessEvent' => :consume_business_event,
        'ChildrensEvent' => :consume_childrens_event,
        'ComedyEvent' => :consume_comedy_event,
        'CourseInstance' => :consume_course_instance,
        'DanceEvent' => :consume_dance_event,
        'DeliveryEvent' => :consume_delivery_event,
        'EducationEvent' => :consume_education_event,
        'EventSeries' => :consume_event_series,
        'ExhibitionEvent' => :consume_exhibition_event,
        'Festival' => :consume_festival,
        'FoodEvent' => :consume_food_event,
        'Hackathon' => :consume_hackathon,
        'LiteraryEvent' => :consume_literary_event,
        'MusicEvent' => :consume_music_event,
        'PublicationEvent' => :consume_publication_event,
        'SaleEvent' => :consume_sale_event,
        'ScreeningEvent' => :consume_screening_event,
        'SocialEvent' => :consume_social_event,
        'SportsEvent' => :consume_sports_event,
        'TheaterEvent' => :consume_theater_event,
        'VisualArtsEvent' => :consume_visual_arts_event,
        'Place' => :consume_place,
        'Brand' => :consume_brand,
        'WebSite' => :consume_website
      }.freeze

      def consume_business_event(data)
        consume_event data
      end

      def consume_childrens_event(data)
        consume_event data
      end

      def consume_comedy_event(data)
        consume_event data
      end

      def consume_dance_event(data)
        consume_event data
      end

      def consume_delivery_event(data)
        consume_event data
      end

      def consume_education_event(data)
        consume_event data
      end

      def consume_exhibition_event(data)
        consume_event data
      end

      def consume_food_event(data)
        consume_event data
      end

      def consume_literary_event(data)
        consume_event data
      end

      def consume_music_event(data)
        consume_event data
      end

      def consume_publication_event(data)
        consume_event data
      end

      def consume_sale_event(data)
        consume_event data
      end

      def consume_screening_event(data)
        consume_event data
      end

      def consume_social_event(data)
        consume_event data
      end

      def consume_sports_event(data)
        consume_event data
      end

      def consume_theater_event(data)
        consume_event data
      end

      def consume_visual_arts_event(data)
        consume_event data
      end

      def consume_course_instance(data); end
      def consume_event_series(data); end
      def consume_festival(data); end
      def consume_hackathon(data); end

      def consume_place(data)
        consume data['event']
      end

      def consume_brand(data); end
      def consume_website(data); end

      def consume_event(data)
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
          graph = data['@graph']
          if graph.present?
            graph.each do |graph_node|
              consume graph_node
            end
            return
          end

          type = data['@type']
          return unless type

          short_type = (type =~ %r{^http://schema.org/(\w+)$}) && Regexp.last_match(1)
          return unless short_type

          dispatch_to = TYPE_DISPATCH[short_type]
          if dispatch_to
            send dispatch_to, data
          else
            Rails.logger.debug { "uknown type '#{type}'" }
          end
          nil
        end
      end

      def validate_events
        events.select! { |ev| ev.valid? && ev.in_future? }
      end

      def events
        @events ||= []
      end
    end

    # the LD-JSON importer part

    def self.handles_url?(calendar)
      try_parser = new(calendar)
      data = try_parser.download_calendar
      events = try_parser.import_events_from(data)

      events.present?
    end

    def initialize(calendar, options = {})
      super calendar, options
    end

    def download_calendar
      # response = HTTParty.get(@url)
      # return [] unless response.success?

      response_body = Base.read_http_source(@url)

      doc = Nokogiri::HTML(response_body)
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
