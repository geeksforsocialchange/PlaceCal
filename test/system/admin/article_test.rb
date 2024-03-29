# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminArticleTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'

    @partner = create :partner
    @partner_two = create :ashton_partner

    @tag = create(:partnership)

    @article = create :article

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on article form' do
    # Edit an article
    click_link 'Articles'
    await_datatables

    click_link @article.title

    author = select2_node 'article_author'
    select2 @root_user.to_s, xpath: author.path
    assert_select2_single @root_user.to_s, author

    partners = select2_node 'article_partners'
    select2 @partner.name, @partner_two.name, xpath: partners.path
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    tags = select2_node 'article_tags'
    select2 @tag.name, xpath: tags.path
    assert_select2_multiple [@tag.name_with_type], tags

    click_button 'Save Article'

    # Check that the changes persist
    click_link 'Articles'
    await_datatables

    click_link @article.title

    author = select2_node 'article_author'
    assert_select2_single @root_user.to_s, author

    partners = select2_node 'article_partners'
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    tags = select2_node 'article_tags'
    assert_select2_multiple [@tag.name_with_type], tags
  end
end
