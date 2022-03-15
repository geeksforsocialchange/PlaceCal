module Types
  ID = GraphQL::Types::ID

  module PartnerQueries
    def self.included(klass)
      klass.field :partner, PartnerType, "Find Partner by ID" do
        argument :id, ID
      end

      klass.field :partner_connection, Types::PartnerType.connection_type
    end

    def partner(id:)
      Partner.find(id)
    end

    def partner_connection(**args)
      Partner.all
    end
  end

  module EventQueries
    def self.included(klass)
      klass.field :event, EventType, "Find Event by ID" do
        argument :id, ID
      end

      klass.field :event_connection, Types::EventType.connection_type

      klass.field :event_by_filter, [Types::EventType] do
        argument :from_date, String, required: false
        argument :to_date, String, required: false
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
      from_date = DateTime.now

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

      # query.where('dtend < ?', args[:end_date]) if args[:end_date]

      query.all
    end
  end

  module SiteQueries
    def self.included(klass)
      klass.field :site, SiteType, "Find Site by ID" do
        argument :id, ID
      end

      klass.field :site_connection, Types::SiteType.connection_type
    end

    def site(id:)
      Site.find(id)
    end

    def site_connection(**args)
      Site.all
    end
  end

  module MiscQueries
    def self.included(klass)
      klass.field :ping, String, null: false, description: "Ping server"
    end

    def ping
      "Hello World! The time is #{Time.now}"
    end
  end

  class QueryType < Types::BaseObject 

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # field :fetch_partners, resolver: Beans # Queries::FetchPartners

    include PartnerQueries
    include EventQueries
    include SiteQueries
    include MiscQueries
  end
end
