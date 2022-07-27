# frozen_string_literal: true

require_relative './application_system_test_case'

class SiteFormTest < ApplicationSystemTestCase
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
    @site = create :site

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on site form' do
    click_sidebar 'sites'
    await_datatables
    click_link 'Add New Site'
    await_select2
    tags = select2_node 'site_tags'
    neighbourhood_main = select2_node 'site_sites_neighbourhood_neighbourhood_id'
    # TODO: main  Neighbourhood HAS TO BE ON NEW SITE
    # TODO: Other  Neighbourhoods what do I do about this cocoon stuff???
    # neighbourhood_others = select2_node 'site_sites_neighbourhoods_neighbourhood_id'
    select2 @tag.name, @tag_pub.name, xpath: tags.path
    assert_select2_multiple [@tag.name, @tag_pub.name], tags
    click_button 'Create Site'

    click_sidebar 'sites'
    await_datatables
    save_and_open_screenshot
    # click_link(@site.name)
    # await_select2
    # tags = select2_node 'site_tags'
    # assert_select2_multiple [@tag.name, @tag_pub.name], tags
  end
end
