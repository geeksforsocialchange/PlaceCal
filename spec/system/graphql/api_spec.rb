# frozen_string_literal: true

require "rails_helper"
require "graphql/client"
require "graphql/client/http"

# Module to interact with the PlaceCal GraphQL API via network connection
module PlaceCalApiClient
  extend self

  PING_QUERY_STRING = "query { ping }"

  ARTICLE_CONNECTION_QUERY_STRING = <<-QUERY
    query { articleConnection { edges {
        node {
          articleBody
          datePublished
          headline
          providers { id }
          image
    } } } }
  QUERY

  PARTNERS_BY_TAG_QUERY_STRING = <<-QUERY
    query($tagId: ID!) {
      partnersByTag(tagId: $tagId) {
        id
        name
        description
        summary
        contact { email, telephone }
        url
        address { streetAddress, postalCode, addressRegion, geo { latitude, longitude } }
        areasServed { name abbreviatedName }
        logo
    } }
  QUERY

  def configure(default_url_options)
    @url = URI::HTTP.build(default_url_options)
    @url.path = "/api/v1/graphql"

    @http   = GraphQL::Client::HTTP.new(@url.to_s)
    @schema = GraphQL::Client.load_schema(@http)
    @client = GraphQL::Client.new(schema: @schema, execute: @http)

    define_constant "PingQuery", @client.parse(PING_QUERY_STRING)
    define_constant "ArticleConnectionQuery", @client.parse(ARTICLE_CONNECTION_QUERY_STRING)
    define_constant "PartnersByTagQuery", @client.parse(PARTNERS_BY_TAG_QUERY_STRING)
  end

  def do_ping_query
    @client.query PingQuery
  end

  def do_article_connection_query
    @client.query ArticleConnectionQuery
  end

  def do_partners_by_tag_query(tag_id)
    @client.query PartnersByTagQuery, variables: { tagId: tag_id }
  end

  private

  def define_constant(name, value)
    return if const_defined?(name)

    const_set name, value
  end
end

RSpec.describe "GraphQL API", :slow, type: :system do
  include ActionDispatch::TestProcess::FixtureFile

  let(:server) { Capybara.current_session.server }

  before do
    # Configure protocol for full URL generation
    Rails.application.default_url_options[:protocol] = "https"

    create_default_site

    app_routes = Rails.application.routes
    app_routes.default_url_options[:host] = server.host
    app_routes.default_url_options[:port] = server.port

    PlaceCalApiClient.configure(app_routes.default_url_options)
  end

  describe "ping query" do
    it "returns a hello world response with timestamp" do
      result = PlaceCalApiClient.do_ping_query

      expect(result.errors).to be_empty
      expect(result.data.ping).to match(/^Hello World! The time is \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
    end
  end

  describe "article connection query" do
    it "returns article with full image URL" do
      upload = fixture_file_upload("good-cat-picture.jpg")
      create(:article, article_image: upload)

      result = PlaceCalApiClient.do_article_connection_query

      article = result.data.article_connection.edges.first.node.to_h
      expect(article).to be_present

      url = article["image"]
      expect(url).to match(%r{\Ahttps://#{server.host}:#{server.port}/})
    end
  end

  describe "partners by tag query" do
    it "returns partner with full logo URL" do
      upload = fixture_file_upload("good-cat-picture.jpg")
      partner = create(:partner, image: upload)
      tag = create(:tag)
      partner.tags << tag

      result = PlaceCalApiClient.do_partners_by_tag_query(tag.id)

      partner_data = result.data.partners_by_tag.first.to_h
      expect(partner_data).to be_present

      url = partner_data["logo"]
      expect(url).to match(%r{\Ahttps://#{server.host}:#{server.port}/})
    end
  end
end
