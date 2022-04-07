# frozen_string_literal: true

require 'test_helper'

class ArticlesByPartnerTagTest < ActionDispatch::IntegrationTest
  test 'returns published articles that are from a partner of a given tag, sorted by publish_date' do
    user = create(:user)

    not_published_article = Article.create!(
      title: "Not published article",
      body: 'article body text',
      author: user
    )

    epoch = DateTime.now.beginning_of_day

    not_tagged_article = Article.create!(
      title: "Not tagged article",
      body: 'article body text',
      author: user,
      is_draft: false,
      published_at: epoch
    )

    tag = create(:tag)
    partner = create(:partner)
    partner.tags << tag

    live_tagged_articles = (0..4).to_a.map do |n|
      article = Article.create!(
        title: "Tagged published article #{n}",
        body: 'article body text',
        author: user,
        is_draft: false
        
      )
      article.update! published_at: epoch + (n + 1).days

      article.partners << partner
      article
    end

    query_string = <<-GRAPHQL
      query {
        articlesByPartnerTag(tagId: #{tag.id}) {
          name
          author
          text
        }
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    refute result.key?('errors'), 'errors are present'

    data = result['data']
    assert data.key?('articlesByPartnerTag')

    articles = data['articlesByPartnerTag']
    assert_equal 5, articles.length, 'expected to only find articles that are published and tagged correctly'

    # newest to oldest
    expected_titles = [ 4, 3, 2, 1, 0 ].map { |index| live_tagged_articles[index].title }
    found_titles = articles.map { |article| article['name'] }
    assert_equal expected_titles, found_titles
  end
end
