# frozen_string_literal: true

module Types
  module EventQueries
    EVENTS_BY_FILTER_LIMIT = 1000

    def self.included(klass)
      klass.field :event, EventType do
        description 'Retrieve one event based on specific ID'
        argument :id, ID, description: 'The ID of the event'
      end

      klass.field :event_connection, Types::EventType.connection_type do
        description 'Get events in chunks'
      end

      klass.field :events_by_filter, [Types::EventType] do
        description \
          'Find events with various filter parameters. By default `eventsByFilter` will show all events from the current time. ' \
          "Returns at most #{EVENTS_BY_FILTER_LIMIT} events, soonest first: narrow the dates or filters to see the rest."

        argument :from_date, String,
                 required: false,
                 description: 'Time to start filter from. Format like "YYYY-MM-DD HH:MM". Defaults to current time. ' \
                              'Can be at most a year before today'

        argument :to_date, String,
                 required: false,
                 description: 'Optional, same format as `fromDate`. Represents a future cut off point to limit query to'

        argument :neighbourhood_id, Integer,
                 required: false,
                 description: 'Will filter events who are inside this neighbourhood, or who have a service area contained in this neighbourhood.'

        argument :tag_id, Integer,
                 required: false,
                 description: 'Will only show events whose partners have this tag'

        argument :postcode, String,
                 required: false,
                 description: 'A UK postcode, e.g. "M15 5FS". Shows events in its ward, or by organisers based or working there when the event has no address.'

        argument :place, String,
                 required: false,
                 description: 'A UK place name: ward, district, county or region, e.g. "Hulme" or "Manchester". ' \
                              'Add the wider area after a comma where names repeat, e.g. "Castle, Cambridge". Matches events like `postcode`.'

        argument :query, String,
                 required: false,
                 description: 'Text to find in event titles and descriptions, case-insensitive, e.g. "yoga".'

        argument :category, String,
                 required: false,
                 description: 'A category name, e.g. "Health & Wellbeing".'
      end
    end

    # A hidden organiser's event gets the same error as a missing id, without the scope's SQL in the message
    def event(id:)
      Event.with_visible_organiser.find_by(id:) ||
        raise(ActiveRecord::RecordNotFound.new("Couldn't find Event with 'id'=#{id.inspect}", Event.name, 'id', id))
    end

    def event_connection(*)
      Event.with_visible_organiser.sort_by_time
    end

    def events_by_filter(**args)
      from_date = args[:from_date].present? ? parse_filter_time(args[:from_date], 'fromDate') : Time.current.beginning_of_day
      raise GraphQL::ExecutionError, 'fromDate is more than a year before today' if from_date < 1.year.ago.beginning_of_day

      to_date = parse_filter_time(args[:to_date], 'toDate') if args[:to_date].present?
      raise GraphQL::ExecutionError, 'toDate is before fromDate' if to_date && to_date <= from_date

      query = EventSearch.new(from: from_date, to: to_date, **args.slice(:postcode, :place, :query, :category)).call

      if args[:neighbourhood_id].present?
        neighbourhood = Neighbourhood.where(id: args[:neighbourhood_id]).first
        raise GraphQL::ExecutionError, "Could not find neighbourhood with that ID (#{args[:neighbourhood_id]})" if neighbourhood.nil?

        query = query.for_neighbourhoods(neighbourhood.subtree)
      end

      if args[:tag_id].present?
        tag = Tag.where(id: args[:tag_id]).first
        raise GraphQL::ExecutionError, "Could not find tag with that ID (#{args[:tag_id]})" if tag.nil?

        query = query.with_tags([tag])
      end

      query.limit(EVENTS_BY_FILTER_LIMIT)
    rescue EventSearch::Error => e
      raise GraphQL::ExecutionError, e.message
    end

    private

    def parse_filter_time(value, name)
      match = value.match(/^\s*(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/)
      raise GraphQL::ExecutionError, "#{name} not in 'YYYY-MM-DD HH:MM' format" unless match

      DateTime.new(*match.captures.map(&:to_i), 0)
    end
  end
end
