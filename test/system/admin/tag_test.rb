# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminTagTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @neighbourhood_admin = create :neighbourhood_admin
    @partner_admin = create :partner_admin

    @partner = @partner_admin.partners.first
    @partner_two = create :ashton_partner
    @tag = create(:tag, name: 'Hulme 1 Tag')

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on tag form' do
    click_link 'Tags'
    click_link @tag.name

    partners = select2_node 'tag_partners'
    select2 @partner.name, @partner_two.name, xpath: partners.path
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    users = select2_node 'tag_users'
    select2 @root_user.to_s, @partner_admin.to_s, xpath: users.path
    assert_select2_multiple [@root_user.to_s, @partner_admin.to_s], users

    click_button 'Save'
    click_link 'Tags'
    click_link @tag.name

    partners = select2_node 'tag_partners'
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    users = select2_node 'tag_users'
    assert_select2_multiple [@root_user.to_s, @partner_admin.to_s], users
  end
end
