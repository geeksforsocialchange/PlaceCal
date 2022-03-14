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
    end

    def event(id:)
      Event.find(id)
    end

    def event_connection(**args)
      Event.sort_by_time.all
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
