# frozen_string_literal: true

require_relative './application_system_test_case'

class NeighbourhoodsFormTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    create_default_site
    create :root, email: 'root@lvh.me'
    @neighbourhood_admin = create(:neighbourhood_admin)
    @partner_admin = create(:partner_admin)

    @partner = @partner_admin.partners.first
    @partner_two = create(:ashton_partner)
    @neighbourhood = @partner.address.neighbourhood
    @neighbourhood_admin.neighbourhoods << @neighbourhood

    @calendar = create(:calendar, partner: @partner, place: @partner)
    @address = create :address
    create :event, address: @address, calendar: @calendar
    create :tag
    create :tag_public

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on neighbourhoods form' do
    click_sidebar 'neighbourhoods'
    await_datatables
    click_link '298486374'
    save_and_open_screenshot
  end
end
