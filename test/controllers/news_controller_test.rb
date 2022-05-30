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

  test 'should get index without subdomain' do
    get news_index_url(subdomain: @site.domain)
    assert_response :success
    assert_select ".article", 5
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
