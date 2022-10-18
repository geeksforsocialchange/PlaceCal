# frozen_string_literal: true

require 'test_helper'

class ArticlesByTagTest < ActionDispatch::IntegrationTest
  test 'returns published articles with tag sorted by publish_date' do
    user = create(:user)

    not_published_article = Article.create!(
      title: 'Not published article',
      body: 'article body text',
      author: user
    )

    epoch = DateTime.now.beginning_of_day

    not_tagged_article = Article.create!(
      title: 'Not tagged article',
      body: 'article body text',
      author: user,
      is_draft: false,
      published_at: epoch
    )

    tag = create(:tag)

    live_tagged_articles = (0..2).to_a.map do |n|
      article = Article.create!(
        title: "Tagged published article #{n}",
        body: 'article body text',
        author: user,
        is_draft: false
      )
      article.update! published_at: epoch + (n + 1).days

      article.tags << tag
      article
    end

    query_string = <<-GRAPHQL
      query {
        articlesByTag(tagId: #{tag.id}) {
          name
          author
          text
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    assert_not result.key?('errors'), 'errors are present'

    data = result['data']
    assert data.key?('articlesByTag')

    articles = data['articlesByTag']
    assert_equal 3, articles.length, 'expected to only find articles that are published and tagged correctly'

    # newest to oldest
    expected_titles = [2, 1, 0].map { |index| live_tagged_articles[index].title }
    found_titles = articles.map { |article| article['name'] }
    assert_equal expected_titles, found_titles
  end
end
