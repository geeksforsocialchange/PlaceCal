# frozen_string_literal: true

require_relative './application_system_test_case'

class PartnerFormTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @partner = create :ashton_partner
    @tag = create :tag
    @tag_pub = create :tag_public
    @neighbourhood_one = neighbourhoods[1].to_s.gsub('w', 'W')
    @neighbourhood_two = neighbourhoods[2].to_s.gsub('w', 'W')

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on partner form' do
    click_sidebar 'partners'
    await_datatables
    click_link @partner.name
    await_select2

    # because of the nested forms we get an array of node
    # the link adds a select2_node to the end of the array
    click_link 'Add Service Area'
    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    select2 @neighbourhood_one, xpath: service_areas[-1].path
    click_link 'Add Service Area'
    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    select2 @neighbourhood_two, xpath: service_areas[-1].path

    assert_select2_single @neighbourhood_one, service_areas[0]
    assert_select2_single @neighbourhood_two, service_areas[1]

    tags = select2_node 'partner_tags'
    select2 @tag.name, @tag_pub.name, xpath: tags.path
    assert_select2_multiple [@tag.name, @tag_pub.name], tags
    click_button 'Save Partner'

    click_sidebar 'partners'
    await_datatables
    click_link @partner.name
    await_select2

    tags = select2_node 'partner_tags'
    assert_select2_multiple [@tag.name, @tag_pub.name], tags

    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    assert_select2_single @neighbourhood_one, service_areas[0]
    assert_select2_single @neighbourhood_two, service_areas[1]
  end
end
