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

  describe "form inputs on partner form" do
    it "allows adding categories and facilities", :aggregate_failures do
      click_link "Partners"
      await_datatables

      click_link partner.name

      # Navigate to Tags tab for categories, facilities (now checkboxes)
      go_to_tags_tab

      # Add category (checkbox)
      check category.name

      # Add facility (checkbox)
      check facility.name

      click_button "Save"

      # Verify save succeeded (flash message shows)
      expect(page).to have_selector("[role='alert']", wait: 10)
    end
  end

  describe "category checkbox limit" do
    # Create specific categories for this test to avoid conflicts
    let!(:test_categories) do
      (1..5).map { |n| create(:category, name: "TestCat#{n}") }
    end

    it "limits category selection to MAX_CATEGORIES", :aggregate_failures do
      click_link "Partners"
      await_datatables
      click_link partner.name

      go_to_tags_tab

      # Wait for checkbox-limit controller to initialize
      expect(page).to have_css("[data-controller='checkbox-limit']", wait: 10)

      # Counter should show 0 selected initially
      expect(page).to have_css("[data-counter]", text: "0 / #{Partner::MAX_CATEGORIES}")

      # Select MAX_CATEGORIES categories using find and click to ensure JS triggers
      Partner::MAX_CATEGORIES.times do |i|
        find(:checkbox, test_categories[i].name).click
        sleep 0.1 # Allow JS to process the change
      end

      # Counter should update to show limit reached
      expect(page).to have_css("[data-counter]", text: "#{Partner::MAX_CATEGORIES} / #{Partner::MAX_CATEGORIES}", wait: 5)

      # Additional checkboxes should be disabled
      remaining_checkbox = find(:checkbox, test_categories[Partner::MAX_CATEGORIES].name, disabled: :all)
      expect(remaining_checkbox).to be_disabled

      # The label should have opacity styling
      expect(remaining_checkbox.find(:xpath, "./ancestor::label")[:class]).to include("opacity-50")

      # Unchecking one should re-enable the others
      find(:checkbox, test_categories[0].name).click
      sleep 0.1

      # Counter should update
      expect(page).to have_css("[data-counter]", text: "#{Partner::MAX_CATEGORIES - 1} / #{Partner::MAX_CATEGORIES}", wait: 5)

      # Previously disabled checkbox should now be enabled
      expect(page).to have_field(test_categories[Partner::MAX_CATEGORIES].name, disabled: false, wait: 5)
    end

    it "initializes counter correctly with pre-selected categories" do
      # Add some categories to the partner
      partner.categories << test_categories[0]
      partner.categories << test_categories[1]

      click_link "Partners"
      await_datatables
      click_link partner.name

      go_to_tags_tab

      # Wait for checkbox-limit controller to initialize
      expect(page).to have_css("[data-controller='checkbox-limit']", wait: 10)

      # Counter should show 2 selected initially
      expect(page).to have_css("[data-counter]", text: "2 / #{Partner::MAX_CATEGORIES}", wait: 5)
    end
  end

  describe "image preview on partner form" do
    it "shows preview when uploading an image" do
      click_link "Partners"
      await_datatables
      click_link partner.name

      # Image upload is on Basic Info tab (default)
      find(:css, "#partner_image", wait: 5)

      image_path = Rails.root.join("spec/fixtures/files/test_image.jpg")
      attach_file "partner_image", image_path

      # Wait for preview image to update (uses Stimulus image-preview controller)
      preview = find(:css, "[data-image-preview-target='img']", visible: true, wait: 5)
      expect(preview["src"]).to start_with("data:image/")
    end
  end

  describe "opening time picker" do
    it "allows adding and removing opening times" do
      click_link "Partners"
      await_datatables
      click_link partner.name

      # Opening times is on the Place tab
      go_to_place_tab

      within '[data-controller="opening-times"]' do
        # Use Stimulus targets for selecting elements
        find('[data-opening-times-target="day"]').select("Sunday")
        find('[data-opening-times-target="allDay"]').check
        click_button "Add Opening Time"

        expected_time = '{"@type":"OpeningHoursSpecification","dayOfWeek":"http://schema.org/Sunday","opens":"00:00:00","closes":"23:59:00"}'
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value

        # New UI uses div elements, not li.list-group-item
        expect(find('[data-opening-times-target="list"] div', text: /Sunday/, wait: 5).text).to include("Sunday all day")
        expect(data).to include(expected_time)

        # Remove the opening time - click the button inside the div
        find('[data-opening-times-target="list"] div', text: /Sunday/).find("button").click
        data = find('[data-opening-times-target="textarea"]', visible: :hidden).value
        expect(data).not_to include(expected_time)
      end
    end

    it "survives missing opening_times value" do
      partner.update!(opening_times: nil)

      click_link "Partners"
      await_datatables
      click_link partner.name

      # Navigate to Tags tab to check that the page loads correctly
      go_to_tags_tab

      # If opening times has malformed data, it will cause problems for
      # the JavaScript that runs the page - verify Tags tab loads
      expect(page).to have_content("Categories", wait: 5)
    end
  end

  describe "service areas" do
    it "allows adding service areas to existing partner" do
      click_link "Partners"
      await_datatables
      click_link partner.name

      # Service areas are on the Location tab
      go_to_place_tab

      # Add a service area using cascading dropdowns
      click_link "Add Service Area"

      # Wait for the cascading neighbourhood controller to initialize
      expect(page).to have_css("[data-controller='cascading-neighbourhood']", wait: 10)

      # The cascading dropdowns should be present
      within(all("[data-controller='cascading-neighbourhood']").last) do
        expect(page).to have_css("[data-cascading-neighbourhood-target='region']")
      end
    end

    it "allows adding service areas to new partner" do
      click_link "Partners"
      await_datatables
      click_link "Add Partner"

      # New Partner form is a 6-step wizard: Name -> Location -> Tags -> Contact -> Invite -> Confirm
      # Step 1: Name
      fill_in "partner_name", with: "Test Partner For Service Areas"
      # Wait for name availability check to complete (debounced 400ms + API call)
      # The name available indicator appears when validation passes
      expect(page).to have_content("This name is available!", wait: 10)
      expect(page).to have_button("Continue", disabled: false)
      click_button "Continue"

      # Step 2: Location - service areas are visible here
      expect(page).to have_content("Set Location", wait: 5)

      # Add a service area using cascading dropdowns
      click_link "Add Service Area"

      # Wait for the cascading neighbourhood controller to initialize
      expect(page).to have_css("[data-controller='cascading-neighbourhood']", wait: 10)

      # The cascading dropdowns should be present
      within(all("[data-controller='cascading-neighbourhood']").last) do
        expect(page).to have_css("[data-cascading-neighbourhood-target='region']")
      end
    end
  end
end
