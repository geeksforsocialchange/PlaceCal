# frozen_string_literal: true

require 'test_helper'

class ArticleIndexTest < ActionDispatch::IntegrationTest
  setup do
  end

  test 'returns articles when invoked' do
    5.times do |n|
      Article.create!(
        title: "News article #{n}",
        body: 'article body text',
        author: 'Foonly McFlooly',
        is_draft: false,
        published_at: DateTime.now
      )
    end

    query_string = <<-GRAPHQL
      query {
        articleConnection {
          edges {
            node {
              name
              text
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result['data']

    assert data.key?('articleConnection'), 'result is missing key `allArticles`'

    article_connection = data['articleConnection']
    edges = article_connection['edges']

    assert edges.length == 5
  end
end
