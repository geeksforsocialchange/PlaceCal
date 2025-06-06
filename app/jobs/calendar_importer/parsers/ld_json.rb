# frozen_string_literal: true

module CalendarImporter::Parsers
  class LdJson < Base
    NAME = 'LD+JSON'
    KEY = 'ld-json'

    def initialize(calendar, options = {})
      super
    end

    DOMAINS = ['various'].freeze

    class EventConsumer
      TYPE_DISPATCH = {
        'Event' => :consume_event,
        'BusinessEvent' => :consume_business_event,
        'ChildrensEvent' => :consume_childrens_event,
        'ComedyEvent' => :consume_comedy_event,
        'CourseInstance' => :consume_course_instance_event,
        'DanceEvent' => :consume_dance_event,
        'DeliveryEvent' => :consume_delivery_event,
        'EducationEvent' => :consume_education_event,
        'EventSeries' => :consume_event_series_event,
        'ExhibitionEvent' => :consume_exhibition_event,
        'Festival' => :consume_festival_event,
        'FoodEvent' => :consume_food_event,
        'Hackathon' => :consume_hackathon_event,
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

      event_types = %w[business childrens course_instance comedy dance delivery education event_series exhibition festival food hackathon literary music publication sale screening social sports theater visual_arts].freeze

      event_types.each do |type|
        define_method(:"consume_#{type}_event") do |data|
          consume_event data
        end
      end

      def consume_place(data)
        consume data['event']
      end

      # TODO: Investigate why these are here, they seem like other types than event?
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
            Rails.logger.debug { "unknown ld+json type '#{type}'" }
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

    def download_calendar
      Base.parse_ld_json(@url)
    end

    def import_events_from(data)
      consumer = EventConsumer.new
      consumer.consume data
      consumer.validate_events
      consumer.events
    end
  end
end
