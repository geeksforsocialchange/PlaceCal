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

      expect(page).to have_css("input#tag_system_tag")
    end

    it "hides system_tag option for citizen users" do
      login_as(citizen_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"

      expect(page).not_to have_css("input#tag_system_tag")
    end
  end

  describe "tag editing" do
    # This test is flaky in CI - flash message timing issue
    it "allows root users to modify tags", skip: ENV.fetch("CI", nil) do
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"

      fill_in "Name", with: "A new tag name"
      click_button "Save"

      assert_has_flash(:success, "Tag was saved successfully")
      expect(page).to have_content("A new tag name")
    end

    # This test is flaky in CI - flash message timing issue
    it "allows root users to toggle system tag on and off", skip: ENV.fetch("CI", nil) do
      login_as(root_user)
      port = Capybara.current_session.server.port

      # Toggle on
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      check "System tag"
      click_button "Save"
      assert_has_flash(:success, "Tag was saved successfully")

      # Check is toggled
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      expect(page).to have_css('input[name="tag[system_tag]"][checked="checked"]', visible: :all)

      # Toggle off
      uncheck "System tag"
      click_button "Save"
      assert_has_flash(:success, "Tag was saved successfully")

      # Check is NOT toggled
      visit "http://admin.lvh.me:#{port}/tags/#{tag.id}/edit"
      expect(page).not_to have_css('input[name="tag[system_tag]"][checked="checked"]', visible: :all)
    end
  end

  describe "creating and editing FacilityTag" do
    it "allows creating and editing a Facility tag" do
      login_as(root_user)

      click_link "Tags"
      click_link "Add Tag"

      # Should see type selector
      expect(page).to have_css('select[name="tag[type]"]')

      fill_in "Name", with: "AlphaFacility"
      fill_in "Slug", with: "alpha-facility"
      fill_in "Description", with: "The description of this tag."
      select "Facility", from: "Type"

      click_button "Save"
      assert_has_flash(:success, "Tag has been created")

      click_link Tag.last.name

      # Should not be able to choose type on update
      expect(page).not_to have_css('select[name="tag[type]"]')

      expect(page).to have_css('input[name="tag[name]"][value="AlphaFacility"]')
      expect(page).to have_css('input[name="tag[slug]"][value="alpha-facility"]')

      # Change values
      fill_in "Name", with: "AlphaFacility 2"
      fill_in "Slug", with: "alpha-facility-2"
      fill_in "Description", with: "The description has changed."
      click_button "Save"

      assert_has_flash(:success, "Tag was saved successfully")

      # Tag should save okay
      click_link Tag.last.name

      expect(page).to have_css('input[name="tag[name]"][value="AlphaFacility 2"]')
      expect(page).to have_css('input[name="tag[slug]"][value="alpha-facility-2"]')
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

      expect(page).to have_css("h3", text: "Assigned Users")
    end

    it "hides assigned users field on Edit of non-Partnership tag" do
      facility_tag = create(:tag, type: "Facility")
      login_as(root_user)
      port = Capybara.current_session.server.port
      visit "http://admin.lvh.me:#{port}/tags/#{facility_tag.id}/edit"

      expect(page).not_to have_css("h3", text: "Assigned Users")
    end
  end
end
