# frozen_string_literal: true

require_relative '../application_system_test_case'

#
# This is basically a stand alone script that pokes the GraphQL endpoint
# running on the server through a network connection (just as how users
# will use the endpoint on staging/production). It does not use any
# internal code like /test/integration/graphql/*
#
# We could be being overly paranoid here but it may become useful for
# catching the kind of bugs that only show up on a real network
# connection.
#
# NOTE: we are mainly interested in testing the endpoints that
# the Trans Dimension elm app uses.

require 'graphql/client'
require 'graphql/client/http'

module PlaceCalApi
  extend self

  PING_QUERY_STRING =
    'query { ping }'

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
    @url.path = '/api/v1/graphql'

    @http   = GraphQL::Client::HTTP.new(@url.to_s)
    @schema = GraphQL::Client.load_schema(@http)
    @client = GraphQL::Client.new(schema: @schema, execute: @http)

    define_constant 'PingQuery', @client.parse(PING_QUERY_STRING)

    define_constant 'ArticleConnectionQuery', @client.parse(ARTICLE_CONNECTION_QUERY_STRING)

    define_constant 'PartnersByTagQuery', @client.parse(PARTNERS_BY_TAG_QUERY_STRING)
  end

  # the API endpoints
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

class GraphQLTest < ApplicationSystemTestCase
  # This tests a number of small (critical) bits of the GraphQL
  # system so its name is bit generic
  # TODO: maybe more tests covering the API?

  include ActionDispatch::TestProcess::FixtureFile

  setup do
    # test that we are sending back the correct protocol as well
    Rails.application.default_url_options[:protocol] = 'https'

    create_default_site

    @server = Capybara.current_session.server

    app_routes = Rails.application.routes
    app_routes.default_url_options[:host] = @server.host
    app_routes.default_url_options[:port] = @server.port

    PlaceCalApi.configure app_routes.default_url_options
  end

  test 'ping works' do
    result = PlaceCalApi.do_ping_query
    assert_empty result.errors
    assert result.data.ping =~ /^Hello World! The time is \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/,
           'missing PING data response'
  end

  test 'news article connection with image url' do
    upload =  fixture_file_upload('good-cat-picture.jpg')
    article = create(:article, article_image: upload)

    result = PlaceCalApi.do_article_connection_query

    article = result.data.article_connection.edges.first.node.to_h
    assert article, 'article node not found'

    url = article['image']
    assert url =~ %r{\Ahttps://#{@server.host}:#{@server.port}/}, 'article image is not full URL'
  end

  test 'partners by tag has correct logo url' do
    upload =  fixture_file_upload('good-cat-picture.jpg')
    partner = create(:partner, image: upload)
    tag = create(:tag)
    partner.tags << tag

    result = PlaceCalApi.do_partners_by_tag_query(tag.id)
    partner = result.data.partners_by_tag.first.to_h
    assert partner

    url = partner['logo']
    assert url =~ %r{\Ahttps://#{@server.host}:#{@server.port}/}, 'partner logo is not full URL'
  end
end
