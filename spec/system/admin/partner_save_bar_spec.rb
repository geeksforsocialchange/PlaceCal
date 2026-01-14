# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partner Save Bar", :slow, type: :system do
  let!(:root_user) do
    create(:root_user,
           email: "root@placecal.org",
           password: "password",
           password_confirmation: "password")
  end

  let!(:partner) { create(:partner) }

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

  def visit_partner_edit
    port = Capybara.current_session.server.port
    visit "http://admin.lvh.me:#{port}/partners/#{partner.id}/edit"
    expect(page).to have_css('input[aria-label="📋 Basic Info"]', wait: 10)
  end

  describe "tab-aware buttons" do
    before do
      login_as(root_user)
      visit_partner_edit
    end

    it "shows Save and Continue buttons on first tab (Basic Info)" do
      expect(page).to have_button("Save")
      expect(page).to have_button("Continue", visible: :all)
      expect(page).not_to have_button("Back", visible: :visible)
    end

    it "shows Back, Save, and Continue buttons on middle tabs" do
      # Go to Location tab
      find('input[aria-label="📍 Location"]').click

      expect(page).to have_button("Back")
      expect(page).to have_button("Save")
      expect(page).to have_button("Continue", visible: :all)
    end

    it "shows Back and Save buttons on Preview tab (no Continue)" do
      # Go to Preview tab
      find('input[aria-label="👁️ Preview"]').click

      expect(page).to have_button("Back")
      expect(page).to have_button("Save")
      expect(page).not_to have_button("Continue", visible: :visible)
    end

    it "shows only Save button on Settings tab" do
      # Go to Settings tab - use data-hash attribute which is more stable than emoji-containing labels
      find('input.tab[data-hash="settings"]').click

      expect(page).to have_button("Save")
      expect(page).not_to have_button("Back", visible: :visible)
      expect(page).not_to have_button("Continue", visible: :visible)
    end
  end

  describe "unsaved changes indicator" do
    before do
      login_as(root_user)
      visit_partner_edit
    end

    it "does not show indicator initially" do
      expect(page).not_to have_selector("[data-save-bar-target='indicator']", visible: :visible)
    end

    it "shows indicator when form field is modified" do
      fill_in "partner[name]", with: "Modified Partner Name"

      expect(page).to have_text("Unsaved changes", wait: 5)
    end

    it "changes button text to include Save when dirty" do
      # Go to a middle tab first
      find('input[aria-label="📍 Location"]').click

      # Initially shows "Back" and "Continue"
      expect(page).to have_button("Back")
      expect(page).to have_button("Continue", visible: :all)

      # Go back to basic and modify
      find('input[aria-label="📋 Basic Info"]').click
      fill_in "partner[name]", with: "Modified Partner Name"

      # Go to location tab again
      # Accept the confirmation dialog
      accept_confirm do
        find('input[aria-label="📍 Location"]').click
      end

      # Now should show "Save & Back" and "Save & Continue"
      expect(page).to have_button("Save & Back", wait: 5)
      expect(page).to have_button("Save & Continue", visible: :all)
    end
  end

  describe "unsaved changes confirmation" do
    before do
      login_as(root_user)
      visit_partner_edit
    end

    it "prompts when switching tabs with unsaved changes" do
      fill_in "partner[name]", with: "Modified Partner Name"

      # Try to switch tabs - should prompt
      dismiss_confirm do
        find('input[aria-label="📍 Location"]').click
      end

      # Should still be on Basic Info tab
      expect(page).to have_css('input[aria-label="📋 Basic Info"]:checked', visible: :all)
    end

    it "allows tab switch when confirmed" do
      fill_in "partner[name]", with: "Modified Partner Name"

      accept_confirm do
        find('input[aria-label="📍 Location"]').click
      end

      # Should now be on Location tab
      expect(page).to have_css('input[aria-label="📍 Location"]:checked', visible: :all)
    end

    it "does not prompt when switching tabs without changes" do
      # Switch tabs without making changes - no prompt expected
      find('input[aria-label="📍 Location"]').click

      # Should be on Location tab
      expect(page).to have_css('input[aria-label="📍 Location"]:checked', visible: :all)
    end
  end

  describe "navigation with Continue/Back buttons" do
    before do
      login_as(root_user)
      visit_partner_edit
    end

    it "navigates to next tab when clicking Continue without changes" do
      # Wait for Continue button to be visible (shown by Stimulus controller)
      expect(page).to have_button("Continue", visible: :visible, wait: 5)
      click_button "Continue"

      # Wait for tab navigation and verify Location tab is checked
      expect(page).to have_css('input[aria-label="📍 Location"]:checked', visible: :all, wait: 5)
    end

    it "navigates to previous tab when clicking Back without changes" do
      # Go to Location tab first
      find('input[aria-label="📍 Location"]').click

      click_button "Back"

      # Should be back on Basic Info tab
      expect(page).to have_css('input[aria-label="📋 Basic Info"]:checked', visible: :all)
    end
  end
end
