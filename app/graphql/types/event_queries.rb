# frozen_string_literal: true

module Types
  module EventQueries
    def self.included(klass)
      klass.field :event, EventType do
        description 'Retrieve one event based on specific ID'
        argument :id, ID
      end

      klass.field :event_connection, Types::EventType.connection_type do
        description 'Get events in chunks'
      end

      klass.field :events_by_filter, [Types::EventType] do
        description \
          'Find events with various filter parameters. By default `eventsByFilter` will show all events from the current time.'

        argument :from_date, String,
                 required: false,
                 description: 'Time to start filter from. Format like "YYYY-MM-DD HH:MM". Defaults to current time'

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
                 description: 'A UK place name: ward, district, county or region, e.g. "Hulme" or "Manchester". Matches events like `postcode`.'

        argument :query, String,
                 required: false,
                 description: 'Text to find in event titles and descriptions, case-insensitive, e.g. "yoga".'

        argument :category, String,
                 required: false,
                 description: 'A category name, e.g. "Health & Wellbeing".'
      end
    end

    def event(id:)
      Event.find(id)
    end

    def event_connection(*)
      Event.sort_by_time.all
    end

    def events_by_filter(**args)
      from_date = Time.current.beginning_of_day
      to_date = nil

      if args[:from_date].present?
        if args[:from_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/
          from_date = DateTime.new(
            Regexp.last_match(1).to_i, # year
            Regexp.last_match(2).to_i, # month
            Regexp.last_match(3).to_i, # day
            Regexp.last_match(4).to_i, # hour
            Regexp.last_match(5).to_i, # minute
            0 # seconds
          )
        else
          raise GraphQL::ExecutionError, "fromDate not in 'YYYY-MM-DD HH:MM' format"
        end
      end

      if args[:to_date].present?
        if args[:to_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/
          to_date = DateTime.new(
            Regexp.last_match(1).to_i, # year
            Regexp.last_match(2).to_i, # month
            Regexp.last_match(3).to_i, # day
            Regexp.last_match(4).to_i, # hour
            Regexp.last_match(5).to_i, # minute
            0       # seconds
          )

          raise GraphQL::ExecutionError, 'toDate is before fromDate' if to_date <= from_date

        else
          raise GraphQL::ExecutionError, "toDate not in 'YYYY-MM-DD HH:MM' format"
        end
      end

      query = EventSearch.new(from: from_date, to: to_date, **args.slice(:postcode, :place, :query, :category)).call

      if args[:neighbourhood_id].present?
        neighbourhood = Neighbourhood.where(id: args[:neighbourhood_id]).first
        if neighbourhood.nil?
          raise GraphQL::ExecutionError, "Could not find neighbourhood with that ID (#{args[:neighbourhood_id]})"
        end

        query = query.for_neighbourhoods(neighbourhood.subtree)
      end

      if args[:tag_id].present?
        tag = Tag.where(id: args[:tag_id]).first
        raise GraphQL::ExecutionError, "Could not find tag with that ID (#{args[:tag_id]})" if tag.nil?

        query = query.with_tags([tag])
      end

      query.all
    rescue EventSearch::Error => e
      raise GraphQL::ExecutionError, e.message
    end
  end
end
