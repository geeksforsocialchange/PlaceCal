# frozen_string_literal: true

require_relative '../application_system_test_case'

class AdminPartnerTest < ApplicationSystemTestCase
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

  test 'image preview on partner form' do
    click_sidebar 'partners'
    await_datatables
    click_link @partner.name
    find(:css, '#partner_image', wait: 15)
    attach_file('partner_image', File.absolute_path('./test/system/admin/damir-omerovic-UMaGtammiSI-unsplash.jpg'))
    base64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/4gIcSUNDX1BST0ZJTEUAAQEAAAIMbGNtcwIQAABtbnRyUkdCIFhZWi'
    preview = find(:css, '.brand_image', wait: 15)
    assert preview['src'].starts_with?(base64), 'The preview image src is not the expected value'
  end

  test 'opening time picker on partner form' do
    click_sidebar 'partners'
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
      assert data.include?(new_time)
      # remove the event
      all(:css, '.list-group-item')[-1].click_button('Remove')
      data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
      # check time is removed from the text area
      assert !data.include?(new_time)
    end
  end

  test 'opening time picker on partner form survives missing value' do
    @partner.update! opening_times: nil

    click_sidebar 'partners'
    await_datatables
    click_link @partner.name
    await_select2

    # very specific bug in the view template here: if opening times has malformed data
    #   it will cause problems for the javascript that runs the partner tags selector
    #   (in the browser). so we verify the select2 code has worked by seeing if it has
    #   correctly done its thing to the tag selector
    assert_selector '.partner_tags ul.select2-selection__rendered'
  end
end
