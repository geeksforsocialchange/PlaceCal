# frozen_string_literal: true

require 'test_helper'

class ArticleIndexTest < ActionDispatch::IntegrationTest
  setup do
  end

  test 'returns articles when invoked' do
    @user = create(:user)
    @partners = create_list(:partner, 2)

    5.times do |n|
      Article.create!(
        title: "News article #{n}",
        body: 'article body text',
        author: @user,
        is_draft: false,
        published_at: DateTime.now,
        partners: @partners
      )
    end

    query_string = <<-GRAPHQL
      query {
        articleConnection {
          edges {
            node {
              name
              headline

              author

              text
              articleBody

              image

              datePublished
              dateCreated
              dateUpdated

              providers {
                id
              }
            }
          }
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result['data']

    assert data.key?('articleConnection'), 'result is missing key `allArticles`'

    edges = data['articleConnection']['edges']
    assert_equal(5, edges.length)

    # Strip the 'node' object container off so we don't have to deal with that
    nodes = edges.map { |edge| edge['node'] }

    nodes.each do |gql_article|
      assert_field gql_article, 'name', 'Article title is nil?'

      assert_not_nil article = Article.find_by(title: gql_article['name']), 'Returned article that doesn\'t exist?'

      assert_field_equals gql_article, 'headline', value: article.title
      assert_field_equals gql_article, 'author', value: article.author_name

      assert_field_equals gql_article, 'text', value: article.body
      assert_field_equals gql_article, 'articleBody', value: article.body

      assert_field_equals gql_article, 'image', value: article.highres_image

      # We only check existence of datePublished simply because there's some iffy goo around how
      # graphql renders T00:00 and how rails renders it. Would probably blow up the code by a fair bit,
      # and honestly if the other values are set, and this one exists, it's Probably Enough To
      assert_field gql_article, 'datePublished'

      assert_field_equals gql_article, 'dateCreated', value: article.created_at.iso8601
      assert_field_equals gql_article, 'dateUpdated', value: article.updated_at.iso8601

      # Partners are Providers, here we are only checking the length of the providers dict because otherwise
      # it just gets super annoying and messy doing nested maps and the like
      providers = assert_field gql_article, 'providers', 'Returned article has no providers'
      assert_equal providers.length, article.partners.length
    end
  end
end
