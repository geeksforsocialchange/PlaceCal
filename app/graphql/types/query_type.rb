module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # field :fetch_partners, resolver: Beans # Queries::FetchPartners

    field :partner, PartnerType, "Find Partner by ID" do
      argument :id, ID
    end

    field :all_partners, [PartnerType]

    def partner(id:)
      Partner.find(id)
    end

    def all_partners
      Partner.all
    end

    field :ping, String, null: false, description: "Ping server"

    def ping
      "Hello World! The time is #{Time.now}"
    end
  end
end
