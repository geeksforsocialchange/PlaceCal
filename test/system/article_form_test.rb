# frozen_string_literal: true

require_relative './application_system_test_case'

class ArticleFormTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partner_admin = create(:partner_admin)

    @partner = @partner_admin.partners.first
    @partner_two = create(:ashton_partner)
    @neighbourhood = @partner.address.neighbourhood
    @neighbourhood_admin.neighbourhoods << @neighbourhood

    @calendar = create(:calendar, partner: @partner, place: @partner)
    @address = create :address
    create :event, address: @address, calendar: @calendar
    @tag = create :tag
    @tag_pub = create :tag_public

    @article = create :article

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on article form' do
    click_sidebar 'articles'
    await_datatables
    click_link(@article.title)
    # click_link '298486374'
    await_select2
    author = select2_node 'article_author'
    partners = select2_node 'article_partners'
    tags = select2_node 'article_tags'

    select2 @root_user.to_s, xpath: author.path
    assert_select2_single @root_user.to_s, author
    select2 @partner.name, @partner_two.name, xpath: partners.path
    assert_select2_multiple [@partner.name, @partner_two.name], partners
    select2 @tag.name, @tag_pub.name, xpath: tags.path
    assert_select2_multiple [@tag.name, @tag_pub.name], tags
    click_button 'Save Article'

    click_sidebar 'articles'
    await_datatables
    click_link(@article.title)
    await_select2
    author = select2_node 'article_author'
    partners = select2_node 'article_partners'
    tags = select2_node 'article_tags'
    assert_select2_single @root_user.to_s, author
    assert_select2_multiple [@partner.name, @partner_two.name], partners
    assert_select2_multiple [@tag.name, @tag_pub.name], tags
  end
end
