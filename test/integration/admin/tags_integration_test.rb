# frozen_string_literal: true

require 'test_helper'

class Admin::TagsTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @citizen = create(:citizen)

    @tag = create(:tag)

    host! 'admin.lvh.me'
  end

  test 'root user editing a tag can see system_tag option' do
    sign_in @root
    get edit_admin_tag_path(@tag)

    assert_select 'input[name="tag[system_tag]"]'
  end

  test 'citizen user editing a tag cannot see system_tag option' do
    sign_in @citizen
    get edit_admin_tag_path(@tag)

    assert_select 'input[name="tag[system_tag]"]', count: 0
  end


=begin
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
=end

end
