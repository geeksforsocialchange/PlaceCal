module Types
  ID = GraphQL::Types::ID

  module PartnerQueries
    def self.included(klass)

      klass.field :partner, PartnerType  do
        description 'Retrieve one Partner based on specific ID'
        argument :id, ID
      end

      klass.field :partner_connection, Types::PartnerType.connection_type do
        description \
          'Get partners in chunks'
      end
    end

    def partner(id:)
      Partner.find(id)
    end

    def partner_connection(**args)
      Partner.all
    end
  end

  module SiteQueries
    def self.included(klass)
      klass.field :site, SiteType do
        description 'Retrieve one Site based on specific ID'
        argument :id, ID
      end

      klass.field :site_connection, Types::SiteType.connection_type do
        description \
          'Get sites in chunks'
      end
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
      klass.field :ping, String,
        null: false,
        description: "Ping server, returns a happy message and a timestamp"
    end

    def ping
      "Hello World! The time is #{Time.now}"
    end
  end

  class QueryType < Types::BaseObject 

    description "The base query schema for all of PlaceCal's GraphQL queries"

    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    include PartnerQueries
    include EventQueries
    include SiteQueries
    include MiscQueries
  end
end
