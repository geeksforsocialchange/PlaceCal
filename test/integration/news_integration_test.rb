# frozen_string_literal: true

require 'test_helper'

class NewsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @site = create(:site)
  end

  test 'shows link if news items present' do
    neighbourhood = neighbourhoods(:one)
    @site.neighbourhoods << neighbourhood

    address = create(:address, neighbourhood: neighbourhood)
    partner = create(:partner, address: address)

    author = create(:root)
    article = Article.create!(
      title: "Article from Partner",
      is_draft: false,
      body: 'lorem ipsum dorem ditsum',
      author: author
    )
    partner.articles << article

    get root_url(subdomain: @site.slug)

    assert_select '.nav li', count: 4
    assert_select '.nav a', text: 'News'
  end

  test 'no news link is shown when no articles exist for site' do
    get root_url(subdomain: @site.slug)

    assert_select '.nav li', count: 3
    assert_select '.nav a', text: 'News', count: 0
  end
end

