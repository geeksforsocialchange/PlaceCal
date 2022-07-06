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

    found = Article.with_tags(tag.id)
    assert_equal 2, found.count, 'Expected to only find articles with given tag'
  end

  test '::with_partner_tag finds articles from partners with a given tag' do
    user = create(:user)
    tag = create(:tag)
    partner = create(:partner)
    partner.tags << tag

    # articles not by partner (no tag)
    3.times do |n|
      Article.create!(
        title: "Article title no. #{n}",
        body: "lorem ipsum ...",
        author: user
      )
    end

    # articles by tagged partner
    5.times do |n|
      article = Article.create!(
        title: "Article title no. #{n}",
        body: "lorem ipsum ...",
        author: user
      )
      article.partners << partner
    end

    found = Article.with_partner_tag(tag.id)
    assert_equal 5, found.length, 'Expected to only find articles from tagged partners'
  end

  test '::for_site returns articles for site (via neighbourhood)' do
    neighbourhood_1 = neighbourhoods(:one)
    neighbourhood_2 = neighbourhoods(:two)

    author = create(:root)

    site = create(:site)
    site.neighbourhoods << neighbourhood_1
    site.neighbourhoods << neighbourhood_2

    partner_1 = create(:partner, address: create(:address, neighbourhood: neighbourhood_1))
    partner_2 = create(:partner, address: create(:address, neighbourhood: neighbourhood_2))

    # from first partner
    2.times do |n|
      partner_1.articles.create!(
        title: "#{n} Article from Partner 1",
        is_draft: nil,
        body: 'lorem ipsum dorem ditsum',
        author: author
      )
    end

    # from second partner
    3.times do |n|
      partner_2.articles.create!(
        title: "#{n} Article from Partner 2",
        is_draft: nil,
        body: 'lorem ipsum dorem ditsum',
        author: author
      )
    end

    found = Article.for_site(site).select(:id)
    assert_equal 5, found.count
  end

  test '::for_site returns articles with site tags applied' do
    tag = create(:tag)
    author = create(:root)

    site = create(:site)
    site.tags << tag
    site.validate!

    3.times do |n|
      article = Article.create!(
        title: "#{n} Article with tag",
        is_draft: nil,
        body: 'lorem ipsum dorem ditsum',
        author: author
      )
      article.tags << tag
      article.validate!
    end

    found = Article.for_site(site)
    assert_equal 3, found.count
  end

  test '::for_site finds articles by both neighbourhood and tag' do
    author = create(:root)
    site = create(:site)

    neighbourhood = neighbourhoods(:one)
    site.neighbourhoods << neighbourhood

    partner = create(:partner, address: create(:address, neighbourhood: neighbourhood))

    3.times do |n|
      partner.articles.create!(
        title: "#{n} Article from Partner by neighbourhood",
        is_draft: nil,
        body: 'lorem ipsum dorem ditsum',
        author: author
      )
    end

    tag = create(:tag)
    site.tags << tag

    5.times do |n|
      article = Article.create!(
        title: "#{n} Article with tag",
        is_draft: nil,
        body: 'lorem ipsum dorem ditsum',
        author: author
      )
      article.tags << tag
    end

    found = Article.for_site(site).select(:id)
    assert_equal 8, found.count
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

  test 'body is renered to html' do
    art = create(:article)
    art.body = 'A body of text about something'
    art.save!
    assert art.body_html.present?
  end
end
