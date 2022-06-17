# frozen_string_literal: true

require 'test_helper'

class NewsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @site = create(:site)

    @neighbourhood = neighbourhoods(:one)
    @site.neighbourhoods << @neighbourhood

    @address = create(:address, neighbourhood: @neighbourhood)
    @author = create(:root)
  end

  test 'shows link if news items present' do
    partner = create(:partner, address: @address)

    article = Article.create!(
      title: "Article from Partner",
      is_draft: false,
      body: 'lorem ipsum dorem ditsum',
      author: @author
    )
    article.partners << partner

    get root_url(subdomain: @site.slug)

    assert_select '.nav li', count: 4
    assert_select '.nav a', text: 'News'
  end

  test 'no news link is shown when no articles exist for site' do
    get root_url(subdomain: @site.slug)

    assert_select '.nav li', count: 3
    assert_select '.nav a', text: 'News', count: 0
  end

  test 'index: articles with partners have parter links' do
    article = create(:article, is_draft: false)
    article.partners << create(:partner, address: @address)
    article.partners << create(:partner, address: @address)

    get news_index_url(subdomain: @site.slug)
    assert_select '.articles__partners a', count: 2
  end

  test 'index: articles with no partners have no partner link component' do
    article = create(:article, is_draft: false)

    get news_index_url(subdomain: @site.slug)
    assert_select '.articles__partners', count: 0
  end

  test 'show: articles with partners have parter links' do
    article = create(:article, is_draft: false)
    article.partners << create(:partner, address: @address)
    article.partners << create(:partner, address: @address)

    get news_url(article, subdomain: @site.slug)
    assert_select '.article__partners a', count: 2
  end

  test 'show: articles with no partners have no partner link component' do
    article = create(:article, is_draft: false)

    get news_url(article, subdomain: @site.slug)
    assert_select '.article__partners', count: 0
  end

  test 'show: author with name shows up' do
    @author.update! first_name: 'Alpha', last_name: 'Beta'

    article = build(:article, is_draft: false)
    article.author = @author
    article.save!

    get news_url(article, subdomain: @site.slug)
    assert_select '.article__author', count: 1, text: 'By Alpha Beta'
  end

  test 'show: author missing name is skipped' do
    @author.update! first_name: '', last_name: ''

    article = build(:article, is_draft: false)
    article.author = @author
    article.save!

    get news_url(article, subdomain: @site.slug)
    assert_select '.article__author', count: 0
  end
end

