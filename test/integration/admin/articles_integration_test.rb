# frozen_string_literal: true

require 'test_helper'

class Admin::ArticlesTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @editor = create(:editor)
    @citizen = create(:citizen)

    @partner_admin = create(:partner_admin)
    @partner = @partner_admin.partners.first

    # Give the Neighbourhood admin a partner in one of their districts :)
    @neighbourhood_admin = create(:neighbourhood_region_admin) do |admin|
      neighbourhood = admin.neighbourhoods.first.children.first # TODO: Refactor this line
      @partner.address.neighbourhood = neighbourhood
      @partner.address.save!
    end

    host! 'admin.lvh.me'
  end

  test 'neighbourhood admin : can see partner on /new' do
    sign_in @neighbourhood_admin
    get new_admin_article_path

    assert_select 'select#article_partner_ids option', @partner.name
  end

  test 'partner admin : partner is preselected on /new' do
    sign_in @partner_admin
    get new_admin_article_path

    assert_select 'select#article_partner_ids option[selected="selected"]', @partner.name
  end

  test 'editor : author is preselected on /new' do
    sign_in @editor
    get new_admin_article_path

    assert_select 'select#article_author_id option[selected="selected"]', @editor.admin_name
  end

  test 'neighbourhood admin : author is preselected on /new' do
    sign_in @neighbourhood_admin
    get new_admin_article_path

    assert_select 'select#article_author_id option[selected="selected"]', @neighbourhood_admin.admin_name
  end

  test 'partner admin : author is preselected on /new' do
    sign_in @partner_admin
    get new_admin_article_path

    assert_select 'select#article_author_id option[selected="selected"]', @partner_admin.admin_name
  end

  test 'new article image upload problem feedback' do
    sign_in @root

    new_article_params = {
      title: 'a new article',
      body: 'alpha beta cappa delta epsilon foxtrot etc',
      author_id: @root.id,
      article_image: fixture_file_upload('bad-cat-picture.bmp')
    }

    post admin_articles_path, params: { article: new_article_params }
    assert_not response.redirect?

    assert_select 'h6', text: '1 error prohibited this Article from being saved'

    # top of page form error box
    assert_select '#form-errors li',
                  text: 'Article image You are not allowed to upload "bmp" files, allowed types: svg, jpg, jpeg, png'

    assert_select 'form .article_article_image .invalid-feedback',
                  text: 'Article image You are not allowed to upload "bmp" files, allowed types: svg, jpg, jpeg, png'
  end

  test 'update article image upload problem feedback' do
    sign_in @root

    article = create(:article)

    article_params = {
      title: article.title,
      body: article.body,
      author_id: article.author_id,
      article_image: fixture_file_upload('bad-cat-picture.bmp')
    }

    put admin_article_path(article), params: { article: article_params }
    assert_not response.successful?

    assert_select 'h6', text: '1 error prohibited this Article from being saved'

    # top of page form error box
    assert_select '#form-errors li',
                  text: 'Article image You are not allowed to upload "bmp" files, allowed types: svg, jpg, jpeg, png'

    assert_select 'form .article_article_image .invalid-feedback',
                  text: 'Article image You are not allowed to upload "bmp" files, allowed types: svg, jpg, jpeg, png'
  end
end
