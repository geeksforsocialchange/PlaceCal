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

      klass.field :partners_by_tag, [PartnerType] do
        description 'Retrieve list of partners that have been given a certain tag'
        argument :tag_id, ID
      end
    end

    def partner(id:)
      Partner.find(id)
    end

    def partner_connection(**args)
      Partner.all
    end

    def partners_by_tag(tag_id:)
      Partner.with_tags(tag_id).order(:name)
    end
  end

  module ArticleQueries
    def self.included(klass)
      #klass.field :all_articles, [ArticleType] do
      #  description 'Return news articles from all sites for all partners'
      #end

      klass.field :article_connection, Types::ArticleType.connection_type do
        description \
          'Get articles in chunks'
      end

      klass.field :articles_by_tag, [Types::ArticleType] do
        description 'Find all news articles that have a given tag attached'
        argument :tag_id, ID
      end
    end

    def article_connection(**args)
      Article.global_newsfeed
    end

    def articles_by_tag(tag_id:)
      Article.with_tag(tag_id).global_newsfeed.order(:title)
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
    include ArticleQueries
    include MiscQueries
  end
end
