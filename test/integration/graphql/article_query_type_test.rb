# frozen_string_literal: true

require 'test_helper'

class ArticleIndexTest< ActionDispatch::IntegrationTest

  setup do
  end

  test 'returns articles when invoked' do

    5.times do |n|
      Article.create!(
        title: "News article #{n}",
        body: 'article body text'
      )
    end

    query_string = <<-GRAPHQL
      query {
        allArticles {
          name
          text
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    # puts JSON.pretty_generate(result.as_json)
    data = result['data']

    assert data.has_key?('allArticles'), 'result is missing key `allArticles`'
    articles = data['allArticles']

    assert articles.length == 5
  end
end
