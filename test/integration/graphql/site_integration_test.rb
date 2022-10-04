# frozen_string_literal: true

require 'test_helper'

class GraphQLSitesTest < ActionDispatch::IntegrationTest
  test 'can show sites' do
    5.times do |n|
      FactoryBot.create(:site, name: "Site #{n}")
    end

    query_string = <<-GRAPHQL
      query {
        siteConnection {
          edges {
            node {
              id
              name
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result['data']

    assert data.key?('siteConnection'), 'result is missing key `siteConnection`'
    connection = data['siteConnection']

    assert connection.key?('edges')
    edges = connection['edges']

    assert_equal(5, edges.length)
  end

  test 'can show specific site' do
    site = FactoryBot.create(:site)

    query_string = <<-GRAPHQL
      query {
        site(id: #{site.id}) {
          id
          name
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)

    data = result['data']
    assert data.key?('site')

    data_site = data['site']
    assert_equal data_site['name'], site.name
  end
end
