# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminPartnerTest < ApplicationSystemTestCase
  include CapybaraSelect2
  include CapybaraSelect2::Helpers
  include Select2Helpers

  setup do
    create_default_site
    @root_user = create :root, email: 'root@lvh.me'
    @partner = create :ashton_partner
    @tag = create :tag
    @tag_pub = create :tag_public
    @neighbourhood_one = neighbourhoods[1].to_s.tr('w', 'W')
    @neighbourhood_two = neighbourhoods[2].to_s.tr('w', 'W')

    # logging in as root user
    visit '/users/sign_in'
    fill_in 'Email', with: 'root@lvh.me'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  test 'select2 inputs on partner form' do
    click_link 'Partners'
    await_datatables

    click_link @partner.name

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

    click_link 'Partners'
    await_datatables

    click_link @partner.name

    tags = select2_node 'partner_tags'
    assert_select2_multiple [@tag.name, @tag_pub.name], tags

    service_areas = all_cocoon_select2_nodes 'sites_neighbourhoods'
    assert_select2_single @neighbourhood_one, service_areas[0]
    assert_select2_single @neighbourhood_two, service_areas[1]
  end

  test 'image preview on partner form' do
    click_link 'Partners'
    await_datatables
    click_link @partner.name
    find :css, '#partner_image', wait: 100

    image_path = File.join(fixture_path, 'files/damir-omerovic-UMaGtammiSI-unsplash.jpg')
    attach_file 'partner_image', image_path

    base64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/4gIcSUNDX1BST0ZJTEUAAQEAAAIMbGNtcwIQAABtbnRyUkdCIFhZWi'
    preview = find(:css, '.brand_image', wait: 15)
    assert preview['src'].starts_with?(base64), 'The preview image src is not the expected value'
  end

  test 'opening time picker on partner form' do
    click_link 'Partners'
    await_datatables

    click_link @partner.name

    within '[data-controller="opening-times"]' do
      # Add an allday event
      select 'Sunday', from: 'day'
      check('All Day')
      click_button 'Add'
      new_time = '{"@type":"OpeningHoursSpecification","dayOfWeek":"http://schema.org/Sunday","opens":"00:00:00","closes":"23:59:00"}'
      data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
      # check it's in the list
      assert all(:css, '.list-group-item')[-1].text.starts_with?('Sunday all day')
      # check it's added to the text area
      assert_includes data, new_time
      # remove the event
      all(:css, '.list-group-item')[-1].click_button('Remove')
      data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
      # check time is removed from the text area
      assert_not_includes data, new_time
    end
  end

  test 'opening time picker on partner form survives missing value' do
    @partner.update! opening_times: nil

    click_link 'Partners'
    await_datatables

    click_link @partner.name
    find :css, '.partner_tags', wait: 100

    # very specific bug in the view template here: if opening times has malformed data
    #   it will cause problems for the javascript that runs the partner tags selector
    #   (in the browser). so we verify the select2 code has worked by seeing if it has
    #   correctly done its thing to the tag selector
    assert_selector '.partner_tags ul.select2-selection__rendered'
  end

  test 'possible to update a partner address without effecting other partners at same address' do
    address = create :ashton_address
    partners = create_list(:partner, 2, address: address)
    assert_equal partners[0].address_id, partners[1].address_id, 'Partners with the same address should have the same address_id'
    click_link 'Partners'
    await_datatables
    click_link partners[0].name
    find(:css, '#partner_address_attributes_street_address').fill_in with: 'new street address'
    click_button 'Save Partner'
    find(:css, '.alert-success')
    assert_not_equal Partner.find(partners[0].id).address, Partner.find(partners[1].id).address, 'updateing one address should not influence the other'
  end

  test 'possible to update a address of all partners that share that address' do
    address = create :ashton_address
    partners = create_list(:partner, 2, address: address)
    assert_equal partners[0].address_id, partners[1].address_id, 'Partners with the same address should have the same address_id'
    click_link 'Partners'
    await_datatables
    click_link partners[0].name
    check 'Update address for all partners at this location'
    find(:css, '#partner_address_attributes_street_address').fill_in with: 'new street address'
    click_button 'Save Partner'
    find(:css, '.alert-success')
    assert_equal Partner.find(partners[0].id).address, Partner.find(partners[1].id).address, 'addesses should remain in sync'
  end
end
