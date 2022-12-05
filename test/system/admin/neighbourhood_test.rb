# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminNeighbourhoodTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @neighbourhood_admin = create :neighbourhood_admin

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on neighbourhoods form' do
    # find first neighbourhood
    click_sidebar 'neighbourhoods'
    await_datatables
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link
    end

    # check that slect2 is working
    await_select2
    users = select2_node 'neighbourhood_users'
    select2 @root_user.to_s, @neighbourhood_admin.to_s, xpath: users.path
    assert_select2_multiple [@root_user.to_s, @neighbourhood_admin.to_s], users
    click_button 'Save'

    click_sidebar 'neighbourhoods'
    await_datatables
    datatable_1st_row = page.all(:css, '.odd')[0]
    within datatable_1st_row do
      click_link
    end

    # check that changes persists
    await_select2
    users = select2_node 'neighbourhood_users'
    assert_select2_multiple [@root_user.to_s, @neighbourhood_admin.to_s], users
  end
end
