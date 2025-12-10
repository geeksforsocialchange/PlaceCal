# frozen_string_literal: true

require 'test_helper'

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @root = create(:root)
    @editor = create(:editor)

    @partner_admin = create(:partner_admin)
    @partner = @partner_admin.partners.first

    @partnerless_neighbourhood_admin = create(:neighbourhood_region_admin)

    # Give the Neighbourhood admin a partner in one of their districts :)
    @neighbourhood_admin = create(:neighbourhood_region_admin) do |admin|
      neighbourhood = admin.neighbourhoods.first.children.first # TODO: Refactor this line
      @partner.address.neighbourhood = neighbourhood
      @partner.address.save!
    end

    @citizen = create(:citizen)

    @article = create(:article) do |article|
      article.partners << @partner
      article.save!
    end
    @unpartnered_article = create(:article)

    @tags = create_list(:tag, 3)
    @partners = create_list(:partner, 3) # I know we already-kinda-have partners; now we have more

    host! 'admin.lvh.me'
  end

  # /index
  # - Show all the articles for Roots, Editors
  # - Show only partner-tagged articles for Partner Admins, and
  #   Neighbourhood Admins who have partners in their neighbourhoods
  # - Redirect for Neighbourhood Admins without partners, and for Citizens

  it_allows_access_to_index_for(%i[root editor]) do
    get admin_articles_url
    assert_response :success

    assert_select 'a', 'Add New Article'
    assert_select 'tbody tr', 2 # We have all 2 articles shown
  end

  it_allows_access_to_index_for(%i[partner_admin neighbourhood_admin]) do
    get admin_articles_url
    assert_response :success

    assert_select 'a', 'Add New Article'
    assert_select 'tbody tr', 1 # Just the one article, actually
  end

  it_denies_access_to_index_for(%i[citizen partnerless_neighbourhood_admin]) do
    get admin_articles_url
    assert_response :redirect
  end

  # /new
  # Basically the same as index
  it_allows_access_to_new_for(%i[root editor partner_admin neighbourhood_admin]) do
    get new_admin_article_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[citizen partnerless_neighbourhood_admin]) do
    get new_admin_article_url
    assert_response :redirect
  end

  # /create
  # Basically the same as index
  it_allows_access_to_create_for(%i[root editor]) do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA' }

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.title, article_hash[:title]
    assert_equal a.author_id, article_hash[:author_id]
    assert_equal a.body, article_hash[:body]
  end

  it_allows_access_to_create_for(%i[partner_admin neighbourhood_admin]) do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA' }

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.title, article_hash[:title]
    assert_equal a.author_id, article_hash[:author_id]
    assert_equal a.body, article_hash[:body]
  end

  it_denies_access_to_create_for(%i[citizen partnerless_neighbourhood_admin]) do
    assert_difference('Article.count', 0) do
      post admin_articles_url,
           params: { article: { title: 'Article Title',
                                author_id: @citizen.id,
                                body: 'AAAAAAAA' } }
    end
  end

  # /edit
  # root, editor = can edit article
  # {partner,neighbourhood}_admin = Allows editing an article that is related to them by a partner
  it_allows_access_to_edit_for(%i[root editor partner_admin neighbourhood_admin]) do
    get edit_admin_article_url(@article)
    assert_response :success
  end

  # A citizen and a neighbourhood_admin without partners should NOT have permission to edit any article
  it_denies_access_to_edit_for(%i[citizen partnerless_neighbourhood_admin]) do
    get edit_admin_article_url(@article)
    assert_response :redirect
  end

  # /update
  it_allows_access_to_update_for(%i[root editor partner_admin neighbourhood_admin]) do
    patch admin_article_url(@article),
          params: { article: { name: 'Foonly' } }

    assert_redirected_to admin_articles_url
  end

  it_denies_access_to_update_for(%i[partnerless_neighbourhood_admin citizen]) do
    patch admin_article_url(@article),
          params: { article: { name: 'Foonly' } }
    assert_redirected_to admin_root_url
  end

  # /destroy
  it_allows_access_to_destroy_for(%i[root editor partner_admin neighbourhood_admin]) do
    assert_difference('Article.count', -1) do
      delete admin_article_url(@article)
    end

    assert_redirected_to admin_articles_url
  end

  it_denies_access_to_destroy_for(%i[partnerless_neighbourhood_admin citizen]) do
    assert_difference('Article.count', 0) do
      delete admin_article_url(@article)
    end
  end

  # --------------------------------------------------------------
  # Just some litmus testing to ensure that the partner_ids and tag_ids are editable by Root/Editor role users
  # These seemed like they should be separate from the above litmus tests
  #
  # Also, TODO: Expand these to be for partners/neighbourhood admins
  # However just note that as per the docs on ArticlePolicy#permitted_attributes, we can't test denial here
  # it needs to be in the integration test :)

  test 'root admin : can create with tag_ids' do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA',
                     tag_ids: @tags.map(&:id) }

    sign_in @root

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.tags.count, @tags.length
  end

  test 'editor admin : can create with tag_ids' do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA',
                     tag_ids: @tags.map(&:id) }

    sign_in @editor

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.tags.count, @tags.length
  end

  test 'root admin : can create with partner_ids' do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA',
                     partner_ids: @partners.map(&:id) }

    sign_in @root

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.partners.count, @partners.length
  end

  test 'editor admin : can create with partner_ids' do
    article_hash = { title: 'Article Title',
                     author_id: @citizen.id,
                     body: 'AAAAAAAAAAAAAAAA',
                     partner_ids: @partners.map(&:id) }

    sign_in @editor

    assert_difference('Article.count') do
      post admin_articles_url,
           params: { article: article_hash }
    end

    a = Article.last
    assert_equal a.partners.count, @partners.length
  end
end
