# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Components::SaveBar, type: :phlex do
  it "renders sticky bar" do
    render_inline(described_class.new) { "Button" }
    expect(page).to have_css(".sticky.bottom-0")
  end

  it "renders button content in simple mode" do
    render_inline(described_class.new) { "Save changes" }
    expect(page).to have_text("Save changes")
  end

  describe "multi-step mode" do
    it "renders save button" do
      render_inline(described_class.new(multi_step: true, tab_name: "tabs"))
      expect(page).to have_css("[data-save-bar-target='saveButton']")
    end

    it "renders back button (hidden)" do
      render_inline(described_class.new(multi_step: true, tab_name: "tabs"))
      expect(page).to have_css("[data-save-bar-target='prevButton']")
    end

    it "renders continue button" do
      render_inline(described_class.new(multi_step: true, tab_name: "tabs"))
      expect(page).to have_css("[data-save-bar-target='continueButton']")
    end

    it "sets stimulus controller data attributes" do
      render_inline(described_class.new(
                      multi_step: true,
                      tab_name: "partner_tabs",
                      settings_hash: "settings",
                      storage_key: "partnerTab"
                    ))
      expect(page).to have_css("[data-controller='save-bar']")
      expect(page).to have_css("[data-save-bar-tab-name-value='partner_tabs']")
      expect(page).to have_css("[data-save-bar-settings-hash-value='settings']")
      expect(page).to have_css("[data-save-bar-storage-key-value='partnerTab']")
    end

    it "renders unsaved changes indicator" do
      render_inline(described_class.new(multi_step: true, tab_name: "tabs"))
      expect(page).to have_css("[data-save-bar-target='indicator']")
    end
  end

  describe "wizard mode" do
    it "renders back button" do
      render_inline(described_class.new(wizard: true, wizard_controller: "my-wizard"))
      expect(page).to have_css("[data-my-wizard-target='backButton']")
    end

    it "renders continue button" do
      render_inline(described_class.new(wizard: true, wizard_controller: "my-wizard"))
      expect(page).to have_css("[data-my-wizard-target='continueButton']")
    end

    it "renders submit button" do
      render_inline(described_class.new(wizard: true, wizard_controller: "my-wizard", submit_label: "Create"))
      expect(page).to have_css("[data-my-wizard-target='submitButton']")
      expect(page).to have_text("Create")
    end
  end

  describe "track changes mode" do
    it "renders unsaved changes indicator" do
      render_inline(described_class.new(track_changes: true)) { "Save" }
      expect(page).to have_css("[data-form-dirty-target='indicator']")
    end
  end
end
