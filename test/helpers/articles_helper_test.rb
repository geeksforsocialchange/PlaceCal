# frozen_string_literal: true

require "test_helper"

class ArticlesHelperTest < ActionView::TestCase
  test "article_summary_text returns summary text" do
    article = build(:article)

    # handles null value
    article.body = nil
    output = article_summary_text(article)
    assert_equal "", output

    # handles short text
    article.body = "This is a body text"
    output = article_summary_text(article)
    assert_equal 19, output.length

    # trims long text
    article.body = "a" * 250
    output = article_summary_text(article)
    assert_equal 200, output.length
  end
end
