# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Tags", :slow, type: :system do
  let!(:root_user) do
    create(:root_user,
           email: "root@placecal.org",
           password: "password",
           password_confirmation: "password")
  end

  let!(:citizen_user) do
    create(:citizen_user,
           email: "citizen@placecal.org",
           password: "password",
           password_confirmation: "password")
  end

  let!(:tag) { create(:tag) }
  let!(:system_tag) { create(:tag, system_tag: true) }

  before do
    create_default_site
  end

  def login_as(user)
    port = Capybara.current_session.server.port
    visit "http://lvh.me:#{port}/users/sign_in"
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
    expect(page).to have_css("h1", text: /Good (morning|afternoon|evening)/) # wait for login redirect
  end

  def assert_has_flash(type, message)
    # Support daisyUI alert classes
    alert_class = type == :success ? "alert-success" : "alert-error"
    expect(page).to have_css("[role='alert'].#{alert_class}, .flashes .alert-#{type}", text: message, wait: 5)
  end

  describe "system tag visibility" do
    it "shows system_tag option for root users" do
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"

      # Wait for tabs to be present, then click Settings
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="settings"]').click
      expect(page).to have_css("input#tag_system_tag")
    end

    # NOTE: Citizen users cannot access the tag edit page at all (TagPolicy#edit? requires root)
    # so there's no need to test that system_tag is hidden for them - they can't see the page.
  end

  describe "tag editing" do
    it "allows root users to modify tags" do
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"

      # Wait for tabs, navigate to Basic Info tab (tab state may be stored from previous tests)
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="basic"]').click

      fill_in "Name", with: "A new tag name"
      click_button "Save"

      assert_has_flash(:success, "Tag was saved successfully")
      expect(page).to have_content("A new tag name")
    end

    it "allows root users to toggle system tag on and off" do
      login_as(root_user)
      port = Capybara.current_session.server.port

      # Toggle on - navigate to Settings tab first
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="settings"]').click
      check "System Tag"
      click_button "Save"
      assert_has_flash(:success, "Tag was saved successfully")

      # Check is toggled - navigate to Settings tab
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="settings"]').click
      expect(page).to have_checked_field("System Tag", visible: :all)

      # Toggle off
      uncheck "System Tag"
      click_button "Save"
      assert_has_flash(:success, "Tag was saved successfully")

      # Check is NOT toggled - navigate to Settings tab
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="settings"]').click
      expect(page).to have_unchecked_field("System Tag", visible: :all)
    end
  end

  describe "creating and editing FacilityTag" do
    it "allows creating and editing a Facility tag" do
      login_as(root_user)

      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/new"

      # Wait for form to be fully loaded
      expect(page).to have_css("input#tag_name", wait: 5)

      fill_in "Name", with: "AlphaFacility"
      fill_in "Slug", with: "alpha-facility"
      fill_in "Description", with: "The description of this tag."
      select "Facility", from: "Type"

      click_button "Save"
      assert_has_flash(:success, "Tag has been created")

      click_link Tag.last.name

      # Should not be able to choose type on update
      expect(page).not_to have_css('select[name="tag[type]"]')

      # Name is on Basic Info tab (default)
      expect(page).to have_css('input[name="tag[name]"][value="AlphaFacility"]')

      # Change name and description on Basic Info tab
      fill_in "Name", with: "AlphaFacility 2"
      fill_in "Description", with: "The description has changed."
      click_button "Save"

      assert_has_flash(:success, "Tag was saved successfully")

      # After save, we stay on the edit page - navigate to Settings tab
      expect(page).to have_css(".tabs.tabs-lift", wait: 10)
      find('input.tab[data-hash="settings"]').click
      expect(page).to have_css('input[name="tag[slug]"][value="alpha-facility"]')
      fill_in "Slug", with: "alpha-facility-2"
      click_button "Save"

      assert_has_flash(:success, "Tag was saved successfully")

      # Tag should save okay - verify slug persisted (we're already on Settings tab after save)
      expect(page).to have_css('input[name="tag[slug]"][value="alpha-facility-2"]')

      # Verify name on Basic Info tab
      find('input.tab[data-hash="basic"]').click
      expect(page).to have_css('input[name="tag[name]"][value="AlphaFacility 2"]')
    end
  end

  describe "assigned users field" do
    it "shows assigned users field on New tag page" do
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/new"

      expect(page).to have_css("h1", text: "New Tag")  # wait for page load
      expect(page).to have_css("h3", text: "Assigned Users")
    end

    it "shows assigned users field on Edit of Partnership tag" do
      partnership_tag = create(:partnership)
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{partnership_tag.id}/edit"

      # Assigned Users is on the Basic Info tab (default)
      expect(page).to have_css("h2", text: "Assigned Users")
    end

    it "hides assigned users field on Edit of non-Partnership tag" do
      facility_tag = create(:tag, type: "Facility")
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{facility_tag.id}/edit"

      # Assigned Users should not show for non-Partnership tags
      expect(page).not_to have_css("h2", text: "Assigned Users")
    end
  end
end
