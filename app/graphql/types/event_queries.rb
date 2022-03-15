module Types
  
  module EventQueries
    def self.included(klass)
      klass.field :event, EventType, "Find Event by ID" do
        argument :id, ID
      end

      klass.field :event_connection, Types::EventType.connection_type

      klass.field :event_by_filter, [Types::EventType] do
        argument :from_date, String, required: false
        argument :to_date, String, required: false
        argument :neighbourhood_id, Integer, required: false
      end
    end

    def event(id:)
      Event.find(id)
    end

    def event_connection(**args)
      Event.sort_by_time.all
    end

    def event_by_filter(**args)
      query = Event.sort_by_time
      from_date = DateTime.now.beginning_of_day

      if args[:from_date].present?
        if args[:from_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/
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
        if args[:to_date] =~ /^\s*(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/
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
        raise GraphQL::ExecutionError, "Could not find neighbourhood with that ID" if neighbourhood.nil?

        query = query.for_neighbourhoods(neighbourhood.subtree)
      end

      # query.where('dtend < ?', args[:end_date]) if args[:end_date]

      query.all
    end
  end
end


