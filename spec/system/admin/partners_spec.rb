# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Partners", :slow, type: :system do
  include_context "admin login"

  # Create wards first, then use them in partner factory to avoid duplicates
  let!(:riverside_ward) { create(:riverside_ward) }
  let!(:oldtown_ward) { create(:oldtown_ward) }
  let!(:partner) { create(:riverside_community_hub, address: create(:address, neighbourhood: riverside_ward)) }
  let!(:partnership) { create(:partnership) }
  let!(:category) { create(:category) }
  let!(:facility) { create(:facility) }

  describe "tom-select inputs on partner form" do
    it "allows adding service areas, partnerships, categories and facilities", :aggregate_failures do
      click_link "Partners"
      await_datatables

      click_link partner.name

      # Add service areas using nested forms
      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      tom_select riverside_ward.name, xpath: service_areas[-1].path

      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      tom_select oldtown_ward.name, xpath: service_areas[-1].path

      assert_tom_select_single riverside_ward.name, service_areas[0]
      assert_tom_select_single oldtown_ward.name, service_areas[1]

      # Add partnership
      partnerships_node = tom_select_node("partner_partnerships")
      tom_select partnership.name, xpath: partnerships_node.path
      assert_tom_select_multiple [partnership.name], partnerships_node

      # Add category
      categories_node = tom_select_node("partner_categories")
      tom_select category.name, xpath: categories_node.path
      assert_tom_select_multiple [category.name], categories_node

      # Add facility
      facilities_node = tom_select_node("partner_facilities")
      tom_select facility.name, xpath: facilities_node.path
      assert_tom_select_multiple [facility.name], facilities_node

      click_button "Save Partner"

      # Verify data persists after save
      click_link "Partners"
      await_datatables
      click_link partner.name

      find_element_with_retry do
        partnerships_node = tom_select_node("partner_partnerships")
        assert_tom_select_multiple [partnership.name], partnerships_node
      end

      find_element_with_retry do
        categories_node = tom_select_node("partner_categories")
        assert_tom_select_multiple [category.name], categories_node
      end

      find_element_with_retry do
        facilities_node = tom_select_node("partner_facilities")
        assert_tom_select_multiple [facility.name], facilities_node
      end

      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      assert_tom_select_single riverside_ward.name, service_areas[0]
      assert_tom_select_single oldtown_ward.name, service_areas[1]
    end
  end

  describe "image preview on partner form" do
    it "shows preview when uploading an image" do
      click_link "Partners"
      await_datatables
      click_link partner.name
      find(:css, "#partner_image", wait: 100)

      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      attach_file "partner_image", image_path

      preview = find(:css, ".brand_image", wait: 15)
      expect(preview["src"]).to start_with("data:image/")
    end
  end

  describe "opening time picker" do
    it "allows adding and removing opening times" do
      click_link "Partners"
      await_datatables
      click_link partner.name

      within '[data-controller="opening-times"]' do
        select "Sunday", from: "day"
        check("All Day")
        click_button "Add"

        expected_time = '{"@type":"OpeningHoursSpecification","dayOfWeek":"http://schema.org/Sunday","opens":"00:00:00","closes":"23:59:00"}'
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value

        expect(all(:css, ".list-group-item").last.text).to start_with("Sunday all day")
        expect(data).to include(expected_time)

        # Remove the opening time
        all(:css, ".list-group-item").last.click_button("Remove")
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
        expect(data).not_to include(expected_time)
      end
    end

    it "survives missing opening_times value" do
      partner.update!(opening_times: nil)

      click_link "Partners"
      await_datatables
      click_link partner.name
      find(:css, ".partner_partnerships", wait: 100)

      # If opening times has malformed data, it will cause problems for
      # the JavaScript that runs the partner tags selector
      expect(page).to have_selector(".partner_partnerships .ts-control")
    end
  end

  describe "duplicate service areas" do
    it "does not crash when adding duplicate service areas to existing partner" do
      click_link "Partners"
      await_datatables
      click_link partner.name

      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      tom_select riverside_ward.name, xpath: service_areas[-1].path

      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      tom_select riverside_ward.name, xpath: service_areas[-1].path

      click_button "Save Partner"
      expect(page).to have_selector(".alert-success")
    end

    it "does not crash when adding duplicate service areas to new partner" do
      click_link "Partners"
      await_datatables
      click_link "Add Partner"

      fill_in "Name", with: "Test Partner"

      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      expect(service_areas).to be_present
      tom_select riverside_ward.name, xpath: service_areas.last.path

      click_link "Add Service Area"
      service_areas = all_nested_form_tom_select_nodes("sites_neighbourhoods")
      expect(service_areas).to be_present
      tom_select riverside_ward.name, xpath: service_areas.last.path

      click_button "Save and continue..."
      expect(page).to have_selector(".alert-success")
    end
  end
end
