require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    @article = build(:article)
  end

  test 'article should be valid' do
    assert @article.valid?
  end

  test 'title should be present' do
    @article.title = ''
    refute @article.valid?
  end

  test 'body should be present' do
    @article.body = ''
    refute @article.valid?
  end
end
