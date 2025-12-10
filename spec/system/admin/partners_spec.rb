# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Partners', :slow, type: :system do
  include_context 'admin login'

  let!(:partner) { create(:riverside_community_hub) }
  let!(:partnership) { create(:partnership) }
  let!(:category) { create(:category) }
  let!(:facility) { create(:facility) }
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }

  describe 'select2 inputs on partner form' do
    it 'allows adding service areas, partnerships, categories and facilities', :aggregate_failures do
      click_link 'Partners'
      await_datatables

      click_link partner.name

      # Add service areas using cocoon nested forms
      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      select2 riverside_ward.name, xpath: service_areas[-1].path

      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      select2 oldtown_ward.name, xpath: service_areas[-1].path

      assert_select2_single riverside_ward.name, service_areas[0]
      assert_select2_single oldtown_ward.name, service_areas[1]

      # Add partnership
      partnerships_node = select2_node('partner_partnerships')
      select2 partnership.name, xpath: partnerships_node.path
      assert_select2_multiple [partnership.name], partnerships_node

      # Add category
      categories_node = select2_node('partner_categories')
      select2 category.name, xpath: categories_node.path
      assert_select2_multiple [category.name], categories_node

      # Add facility
      facilities_node = select2_node('partner_facilities')
      select2 facility.name, xpath: facilities_node.path
      assert_select2_multiple [facility.name], facilities_node

      click_button 'Save Partner'

      # Verify data persists after save
      click_link 'Partners'
      await_datatables
      click_link partner.name

      find_element_with_retry do
        partnerships_node = select2_node('partner_partnerships')
        assert_select2_multiple [partnership.name], partnerships_node
      end

      find_element_with_retry do
        categories_node = select2_node('partner_categories')
        assert_select2_multiple [category.name], categories_node
      end

      find_element_with_retry do
        facilities_node = select2_node('partner_facilities')
        assert_select2_multiple [facility.name], facilities_node
      end

      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      assert_select2_single riverside_ward.name, service_areas[0]
      assert_select2_single oldtown_ward.name, service_areas[1]
    end
  end

  describe 'image preview on partner form' do
    it 'shows preview when uploading an image' do
      click_link 'Partners'
      await_datatables
      click_link partner.name
      find(:css, '#partner_image', wait: 100)

      image_path = Rails.root.join('spec/fixtures/files/test_image.jpg')
      attach_file 'partner_image', image_path

      preview = find(:css, '.brand_image', wait: 15)
      expect(preview['src']).to start_with('data:image/')
    end
  end

  describe 'opening time picker' do
    it 'allows adding and removing opening times' do
      click_link 'Partners'
      await_datatables
      click_link partner.name

      within '[data-controller="opening-times"]' do
        select 'Sunday', from: 'day'
        check('All Day')
        click_button 'Add'

        expected_time = '{"@type":"OpeningHoursSpecification","dayOfWeek":"http://schema.org/Sunday","opens":"00:00:00","closes":"23:59:00"}'
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value

        expect(all(:css, '.list-group-item').last.text).to start_with('Sunday all day')
        expect(data).to include(expected_time)

        # Remove the opening time
        all(:css, '.list-group-item').last.click_button('Remove')
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
        expect(data).not_to include(expected_time)
      end
    end

    it 'survives missing opening_times value' do
      partner.update!(opening_times: nil)

      click_link 'Partners'
      await_datatables
      click_link partner.name
      find(:css, '.partner_partnerships', wait: 100)

      # If opening times has malformed data, it will cause problems for
      # the JavaScript that runs the partner tags selector
      expect(page).to have_selector('.partner_partnerships ul.select2-selection__rendered')
    end
  end

  describe 'duplicate service areas' do
    it 'does not crash when adding duplicate service areas to existing partner' do
      click_link 'Partners'
      await_datatables
      click_link partner.name

      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      select2 riverside_ward.name, xpath: service_areas[-1].path

      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      select2 riverside_ward.name, xpath: service_areas[-1].path

      click_button 'Save Partner'
      expect(page).to have_selector('.alert-success')
    end

    it 'does not crash when adding duplicate service areas to new partner' do
      click_link 'Partners'
      await_datatables
      click_link 'Add New Partner'

      fill_in 'Name', with: 'Test Partner'

      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      expect(service_areas).to be_present
      select2 riverside_ward.name, xpath: service_areas.last.path

      click_link 'Add Service Area'
      service_areas = all_cocoon_select2_nodes('sites_neighbourhoods')
      expect(service_areas).to be_present
      select2 riverside_ward.name, xpath: service_areas.last.path

      click_button 'Save and continue...'
      expect(page).to have_selector('.alert-success')
    end
  end
end
