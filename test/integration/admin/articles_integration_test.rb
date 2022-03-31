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

    pp assert_select 'select#article_author_id option[selected="selected"]', @editor.admin_name
  end

  test 'neighbourhood admin : author is preselected on /new' do
    sign_in @neighbourhood_admin
    get new_admin_article_path

    assert_select 'select#article_author_id option[selected="selected"]', @neighbourhood_admin.admin_name
  end

  test 'partner admin : author is preselected on /new' do
    sign_in @partner_admin
    get new_admin_article_path

    pp assert_select 'select#article_author_id option[selected="selected"]', @partner_admin.admin_name
  end
end
