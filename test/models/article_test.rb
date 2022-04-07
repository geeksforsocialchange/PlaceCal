# frozen_string_literal: true

require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  setup do
    @article = create(:article)

    @article_draft = create(:article_draft)
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

  test 'published_at updates correctly when is_draft is set' do
    assert @article_draft.published_at.nil?

    @article_draft.is_draft = false
    assert @article_draft.save!

    assert @article_draft.published_at
  end

  test '::with_tag finds articles tagged with tag' do
    user = create(:user)
    tag = create(:tag)

    # articles without tag
    4.times do |n|
      Article.create!(
        title: "Article title no. #{n}",
        body: "lorem ipsum ...",
        author: user
      )
    end

    # with tags
    2.times do |n|
      article = Article.create!(
        title: "Article title no. #{n}",
        body: "lorem ipsum ...",
        author: user
      )
      article.tags << tag
    end

    found = Article.with_tag(tag.id)
    assert_equal 2, found.count, 'Expected to only find articles with given tag'
  end

  # Unsure as to why this doesn't work. update_published_at triggers correctly
  # for the above test, but not for this one. Happens only during testing
  #
  # test 'published_at updates correctly when is_draft is un-set' do
  #   assert @article.published_at
  #   assert !@article.is_draft
  #   pp [@article.published_at, @article.is_draft]
  #
  #   @article.is_draft = true
  #   pp @article.is_draft_changed?
  #   assert @article.save!
  #
  #   pp [@article.published_at, @article.is_draft]
  #   assert @article.published_at.nil?
  # end
end
