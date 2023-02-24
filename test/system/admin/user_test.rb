# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminUserTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    create :root, email: 'root@lvh.me'
    @neighbourhood_admin = create :neighbourhood_admin
    @partner_admin = create :partner_admin

    @partner = @partner_admin.partners.first
    @partner_two = create :ashton_partner

    @tag = create :tag

    @neighbourhood_one = neighbourhoods[1].to_s.tr('w', 'W')
    @neighbourhood_two = neighbourhoods[2].to_s.tr('w', 'W')

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on users form' do
    click_link 'Users'

    # edit a root user because they have access to all potential select2 inputs
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link 'Place'
    end

    partners = select2_node 'user_partners'
    select2 @partner.name, @partner_two.name, xpath: partners.path
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    neighbourhoods = select2_node 'user_neighbourhoods'
    select2 @neighbourhood_one, @neighbourhood_two, xpath: neighbourhoods.path
    assert_select2_multiple [@neighbourhood_one, @neighbourhood_two], neighbourhoods

    tags = select2_node 'user_tags'
    select2 @tag.name, xpath: tags.path
    assert_select2_multiple [@tag.name], tags
    click_button 'Update'

    click_link 'Users'

    # return to user to check data is intact
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link 'Place'
    end

    partners = select2_node 'user_partners'
    assert_select2_multiple [@partner.name, @partner_two.name], partners

    neighbourhoods = select2_node 'user_neighbourhoods'
    assert_select2_multiple [@neighbourhood_one, @neighbourhood_two], neighbourhoods

    tags = select2_node 'user_tags'
    assert_select2_multiple [@tag.name], tags
  end
end
