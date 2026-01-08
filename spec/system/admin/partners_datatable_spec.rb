# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe "Admin Partners Datatable", :slow, type: :system do
  include_context "admin login"

  # Test data setup
  let!(:district) { create(:neighbourhood, name: "Test District", unit: "district") }
  let!(:ward1) { create(:neighbourhood, name: "Ward Alpha", unit: "ward", parent: district) }
  let!(:ward2) { create(:neighbourhood, name: "Ward Beta", unit: "ward", parent: district) }

  let!(:partnership1) { create(:partnership, name: "Partnership One") }
  let!(:partnership2) { create(:partnership, name: "Partnership Two") }

  let!(:category1) { create(:category, name: "Health Services") }
  let!(:category2) { create(:category, name: "Sports Activities") }

  let!(:partner_alpha) do
    address = create(:address, neighbourhood: ward1)
    partner = create(:partner, name: "Alpha Community Centre", address: address)
    create(:calendar, partner: partner)
    create(:partner_admin, partner: partner)
    partner.tags << partnership1
    partner.tags << category1
    partner
  end

  let!(:partner_beta) do
    address = create(:address, neighbourhood: ward2)
    partner = create(:partner, name: "Beta Youth Club", address: address)
    partner.tags << partnership2
    partner.tags << category2
    partner
  end

  let!(:partner_gamma) do
    address = create(:address, neighbourhood: ward1)
    create(:partner, name: "Gamma Sports Hall", address: address)
  end

  before do
    click_link "Partners"
    wait_for_datatable
  end

  def wait_for_datatable
    expect(page).to have_css("[data-admin-table-target='tbody'] tr", minimum: 1, wait: 10)
  end

  def datatable_row_count
    all("[data-admin-table-target='tbody'] tr").count
  end

  def datatable_contains(text)
    within("[data-admin-table-target='tbody']") do
      expect(page).to have_content(text)
    end
  end

  def datatable_does_not_contain(text)
    within("[data-admin-table-target='tbody']") do
      expect(page).not_to have_content(text)
    end
  end

  describe "initial load" do
    it "displays all partners" do
      expect(datatable_row_count).to eq(3)
      datatable_contains("Alpha Community Centre")
      datatable_contains("Beta Youth Club")
      datatable_contains("Gamma Sports Hall")
    end

    it "shows total record count in summary" do
      within("[data-admin-table-target='summary']") do
        expect(page).to have_content("3 total records")
      end
    end

    it "displays partner details in columns" do
      within("[data-admin-table-target='tbody']") do
        expect(page).to have_content("Ward Alpha")
        expect(page).to have_content("Partnership One")
      end
    end
  end

  describe "search functionality" do
    it "filters partners by name" do
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5 # Wait for debounce

      wait_for_datatable
      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
      datatable_does_not_contain("Beta Youth Club")
    end

    it "shows no results message for non-matching search" do
      fill_in "Search by name...", with: "nonexistent12345"
      sleep 0.5

      expect(page).to have_content("No records found")
    end

    it "clears search when input is emptied" do
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5
      wait_for_datatable

      fill_in "Search by name...", with: ""
      sleep 0.5
      wait_for_datatable

      expect(datatable_row_count).to eq(3)
    end

    it "search is case insensitive" do
      fill_in "Search by name...", with: "ALPHA"
      sleep 0.5
      wait_for_datatable

      datatable_contains("Alpha Community Centre")
    end
  end

  describe "sorting" do
    it "sorts by partner name ascending when clicking header" do
      click_on "Partner"
      wait_for_datatable

      rows = all("[data-admin-table-target='tbody'] tr")
      expect(rows.first.text).to include("Alpha")
    end

    it "toggles sort direction on second click" do
      click_on "Partner"
      wait_for_datatable
      click_on "Partner"
      wait_for_datatable

      rows = all("[data-admin-table-target='tbody'] tr")
      expect(rows.first.text).to include("Gamma")
    end

    it "shows reset sort button after changing sort" do
      expect(page).not_to have_button("Reset sort")

      click_on "Partner"
      wait_for_datatable

      expect(page).to have_button("Reset sort")
    end

    it "resets sort to default when clicking reset button" do
      # Change from default sort
      click_on "Partner"
      wait_for_datatable

      click_button "Reset sort"
      wait_for_datatable

      expect(page).not_to have_button("Reset sort")
    end
  end

  describe "calendar status filter" do
    it "filters to show only partners with calendars" do
      select "Connected", from: "Calendar"
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end

    it "filters to show only partners without calendars" do
      select "No calendar", from: "Calendar"
      wait_for_datatable

      expect(datatable_row_count).to eq(2)
      datatable_does_not_contain("Alpha Community Centre")
    end
  end

  describe "admin users filter" do
    it "filters to show only partners with admins" do
      select "Has admins", from: "Admins"
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end

    it "filters to show only partners without admins" do
      select "No admins", from: "Admins"
      wait_for_datatable

      expect(datatable_row_count).to eq(2)
      datatable_does_not_contain("Alpha Community Centre")
    end
  end

  describe "category filter" do
    it "filters by selected category" do
      select "Health Services", from: "Category"
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end
  end

  describe "partnership filter" do
    it "filters by selected partnership" do
      select "Partnership One", from: "Partnership"
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end

    it "clicking partnership name in table filters to that partnership" do
      within("[data-admin-table-target='tbody']") do
        click_button "Partnership One"
      end
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end
  end

  describe "cascading district/ward filter" do
    it "shows ward dropdown only after selecting district" do
      # Ward dropdown should be hidden initially
      expect(page).to have_select("District")
      expect(page).to have_css("select[data-filter-column='ward'].hidden", visible: :hidden)
    end

    it "shows ward dropdown after selecting district" do
      select "Test District", from: "District"

      # Ward dropdown should now be visible
      expect(page).to have_select("Ward", visible: true)
    end

    it "ward dropdown only shows wards from selected district" do
      select "Test District", from: "District"

      ward_select = find("select[data-filter-column='ward']")
      expect(ward_select).to have_css("option", text: "Ward Alpha")
      expect(ward_select).to have_css("option", text: "Ward Beta")
    end

    it "selecting district filters partners" do
      select "Test District", from: "District"
      wait_for_datatable

      # All partners are in this district's wards
      expect(datatable_row_count).to eq(3)
    end

    it "selecting ward further filters partners" do
      select "Test District", from: "District"
      wait_for_datatable

      select "Ward Alpha", from: "Ward"
      wait_for_datatable

      expect(datatable_row_count).to eq(2)
      datatable_contains("Alpha Community Centre")
      datatable_contains("Gamma Sports Hall")
      datatable_does_not_contain("Beta Youth Club")
    end

    it "changing district clears ward selection" do
      select "Test District", from: "District"
      select "Ward Alpha", from: "Ward"
      wait_for_datatable

      # Clear district selection
      select "District", from: "District"

      expect(page).to have_css("select[data-filter-column='ward'].hidden", visible: :hidden)
    end
  end

  describe "multiple filters combined" do
    it "applies multiple filters simultaneously" do
      select "Has admins", from: "Admins"
      select "Health Services", from: "Category"
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end

    it "shows clear filters button when filters are active" do
      expect(page).not_to have_button("Clear filters")

      select "Has admins", from: "Admins"
      wait_for_datatable

      expect(page).to have_button("Clear filters")
    end

    it "clears all filters when clicking clear button" do
      select "Has admins", from: "Admins"
      select "Health Services", from: "Category"
      wait_for_datatable

      click_button "Clear filters"
      wait_for_datatable

      expect(datatable_row_count).to eq(3)
      expect(page).not_to have_button("Clear filters")
    end
  end

  describe "search combined with filters" do
    it "applies both search and filter" do
      select "Partnership One", from: "Partnership"
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5
      wait_for_datatable

      expect(datatable_row_count).to eq(1)
      datatable_contains("Alpha Community Centre")
    end

    it "clear filters does not clear search" do
      select "Has admins", from: "Admins"
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5
      wait_for_datatable

      click_button "Clear filters"
      wait_for_datatable

      # Search should still be active
      expect(find_field("Search by name...").value).to eq("Alpha")
      datatable_contains("Alpha Community Centre")
    end
  end

  describe "pagination" do
    before do
      # Create enough partners for pagination
      30.times { |i| create(:partner, name: "Paginated Partner #{i.to_s.rjust(2, '0')}") }
      visit current_path # Reload to get new partners
      wait_for_datatable
    end

    it "shows pagination controls when more than one page" do
      expect(page).to have_css("[data-admin-table-target='pagination']")
    end

    it "navigates to next page" do
      # Find and click next page button
      within("[data-admin-table-target='pagination']") do
        find("a[data-action='admin-table#nextPage']").click
      end
      wait_for_datatable

      # Should show different partners on page 2
      expect(page).to have_content("26–")
    end

    it "shows current page info" do
      expect(page).to have_content("1–25 of")
    end
  end

  describe "clicking ward in table" do
    it "filters by that ward when clicking ward name" do
      within("[data-admin-table-target='tbody']") do
        click_button "Ward Alpha"
      end
      wait_for_datatable

      expect(datatable_row_count).to eq(2)
      datatable_contains("Alpha Community Centre")
      datatable_contains("Gamma Sports Hall")
    end
  end

  describe "edit partner link" do
    it "navigates to edit page when clicking partner name" do
      within("[data-admin-table-target='tbody']") do
        click_link "Alpha Community Centre"
      end

      expect(page).to have_content("Edit Partner")
      expect(page).to have_content("Alpha Community Centre")
    end

    it "navigates to edit page when clicking Edit button" do
      within("[data-admin-table-target='tbody'] tr", text: "Alpha") do
        click_link "Edit"
      end

      expect(page).to have_content("Edit Partner")
    end
  end

  describe "updated at column" do
    it "shows relative time for recent updates" do
      partner_alpha.touch

      visit current_path
      wait_for_datatable

      within("[data-admin-table-target='tbody'] tr", text: "Alpha") do
        expect(page).to have_content("Today")
      end
    end
  end

  describe "status indicators" do
    it "shows check icon for partner with calendar" do
      within("[data-admin-table-target='tbody'] tr", text: "Alpha") do
        # Calendar column should have green check
        expect(page).to have_css(".text-emerald-600 svg")
      end
    end

    it "shows cross icon for partner without calendar" do
      within("[data-admin-table-target='tbody'] tr", text: "Beta") do
        # Calendar column should have gray cross
        expect(page).to have_css(".text-gray-400 svg")
      end
    end
  end

  describe "summary display updates" do
    it "updates summary when filter reduces results" do
      select "Has admins", from: "Admins"
      wait_for_datatable

      within("[data-admin-table-target='summary']") do
        expect(page).to have_content("Showing 1 of 3 records")
      end
    end

    it "updates summary when search reduces results" do
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5
      wait_for_datatable

      within("[data-admin-table-target='summary']") do
        expect(page).to have_content("Showing 1 of 3 records")
      end
    end

    it "reverts summary when filters cleared" do
      select "Has admins", from: "Admins"
      wait_for_datatable

      click_button "Clear filters"
      wait_for_datatable

      within("[data-admin-table-target='summary']") do
        expect(page).to have_content("3 total records")
      end
    end

    it "shows combined filter and search count" do
      select "Partnership One", from: "Partnership"
      fill_in "Search by name...", with: "Alpha"
      sleep 0.5
      wait_for_datatable

      within("[data-admin-table-target='summary']") do
        expect(page).to have_content("Showing 1 of 3 records")
      end
    end
  end

  describe "empty state" do
    before do
      Partner.destroy_all
      visit current_path
    end

    it "shows empty state message when no partners" do
      expect(page).to have_content("No records found")
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
