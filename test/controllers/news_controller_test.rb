# frozen_string_literal: true

require 'test_helper'

class NewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = create(:root)
    @neighbourhood = neighbourhoods(:one)

    @partner = create(:partner, address: create(:address, neighbourhood: @neighbourhood))
    @articles = (0...5).map do |n|
      @partner.articles.create!(
            title: "#{n} Article",
            is_draft: false,
            body: 'Some text about this news piece',
            author: @author)
    end

    @site = create(:site)
    @site.neighbourhoods << @neighbourhood
  end

  test 'should get index subdomain' do
    get news_index_url(subdomain: @site.domain)
    assert_response :success
    assert_select ".articles__article-card", 5

    # counts
    # assert_select 'p', { text: 'Found 5 articles.' }

    # pagination
    # assert_select 'p', { text: 'No more news items' }
    assert_select 'p', { count: 0, text: 'Older news items' }
  end

  test "with too many articles only 20 are shown and a 'more content' link" do
    @articles += (0...25).map do |n|
      @partner.articles.create!(
        title: "#{n} Article, again",
        is_draft: false,
        body: 'Some text about this news piece',
        author: @author)
    end

    @epoch = Date.new(2000, 1, 31)
    @articles.each.with_index do |art, n|
      art.update! published_at: @epoch - n
    end

    get news_index_url(subdomain: @site.domain)
    assert_response :success

    # this is capped
    assert_select ".articles__article-card", NewsController::ARTICLES_PER_PAGE

    # counts
    # assert_select 'p', { text: 'Found 30 articles.' }

    # pagination
    # assert_select 'p', { count: 0, text: 'No more news items' }
    assert_select 'p', { text: 'Older news items' }

    get news_index_url(subdomain: @site.domain, offset: 20)

    assert_select ".articles__article-card", 10 # only ten left

    # pagination
    # assert_select 'p', { text: 'No more news items' }
    assert_select 'p', { count: 0, text: 'Older news items' }
  end


  #test 'should get index with configured subdomain' do
  #  get url_for controller: :news, subdomain: @site.slug
  #  assert_response :success
  #  assert_select "ol.events li", 5
  #end

  test 'should get index with invalid subdomain' do
    get url_for controller: :news, subdomain: "notaknownsubdomain"
    assert_response :redirect
  end

  test 'should show event' do
    get news_url(@articles.first, subdomain: @site.domain)
    assert_response :success
  end
end
