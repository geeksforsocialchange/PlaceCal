require "test_helper"

class ArticlePartnerTest < ActiveSupport::TestCase
  setup do
    @partner = create(:partner)
    @article = create(:article)
  end

  test 'create article for partner' do
    @partner.articles << @article
    assert_equal @partner.articles.count, 1
  end
end