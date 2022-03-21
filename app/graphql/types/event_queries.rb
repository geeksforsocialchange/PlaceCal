module Types
  
  module EventQueries
    def self.included(klass)
      klass.field :event, EventType do
        description 'Retrieve one event based on specific ID'
        argument :id, ID
      end

      klass.field :event_connection, Types::EventType.connection_type do
        description "Get events in chunks"
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
      end
    end

    def event(id:)
      Event.find(id)
    end

    def event_connection(**args)
      Event.sort_by_time.all
    end

    def events_by_filter(**args)
      query = Event.sort_by_time
      from_date = DateTime.now.beginning_of_day

      if args[:from_date].present?
        if args[:from_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/
          from_date = DateTime.new(
            $1.to_i, # year
            $2.to_i, # month
            $3.to_i, # day
            $4.to_i, # hour
            $5.to_i, # minute
            0,       # seconds
          )
        else
          raise GraphQL::ExecutionError, "fromDate not in 'YYYY-MM-DD HH:MM' format"
        end
      end

      query = query.where('dtstart >= ?', from_date)

      if args[:to_date].present?
        if args[:to_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})/
          to_date = DateTime.new(
            $1.to_i, # year
            $2.to_i, # month
            $3.to_i, # day
            $4.to_i, # hour
            $5.to_i, # minute
            0,       # seconds
          )

          if to_date <= from_date
            raise GraphQL::ExecutionError, "toDate is before fromDate"
          end

        else
          raise GraphQL::ExecutionError, "toDate not in 'YYYY-MM-DD HH:MM' format"
        end

        query = query.where('dtstart < ?', to_date)
      end

      if args[:neighbourhood_id].present?
        neighbourhood = Neighbourhood.where(id: args[:neighbourhood_id]).first
        raise GraphQL::ExecutionError, "Could not find neighbourhood with that ID (#{args[:neighbourhood_id]})" if neighbourhood.nil?

        query = query.for_neighbourhoods(neighbourhood.subtree)
      end

      if args[:tag_id].present?
        tag = Tag.where(id: args[:tag_id]).first
        raise GraphQL::ExecutionError, "Could not find tag with that ID (#{args[:tag_id]})" if tag.nil?

        query = query.for_tag(tag)
      end

      query.all
    end
  end
end
