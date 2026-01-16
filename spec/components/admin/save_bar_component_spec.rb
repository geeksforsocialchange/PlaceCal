# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SaveBarComponent, type: :component do
  describe "simple mode (default)" do
    it "renders as a sticky bar" do
      render_inline(described_class.new)
      expect(page).to have_css(".sticky.bottom-0")
    end

    it "renders custom buttons via slot" do
      component = described_class.new
      render_inline(component) do |c|
        c.with_button { "<button class='custom-btn'>Save</button>".html_safe }
      end
      expect(page).to have_css(".custom-btn", text: "Save")
    end

    it "does not render multi-step controls in simple mode" do
      render_inline(described_class.new)
      expect(page).not_to have_css("[data-save-bar-target='prevButton']")
      expect(page).not_to have_css("[data-save-bar-target='continueButton']")
    end
  end

  describe "multi-step mode" do
    let(:multi_step_params) do
      {
        multi_step: true,
        tab_name: "partner_tabs",
        settings_hash: "settings",
        preview_hash: "preview",
        storage_key: "partnerTabAfterSave"
      }
    end

    it "renders back button in multi-step mode" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-target='prevButton']")
    end

    it "renders save button in multi-step mode" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-target='saveButton']")
    end

    it "renders continue button in multi-step mode" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-target='continueButton']")
    end

    it "renders unsaved changes indicator" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-target='indicator']")
    end

    it "includes save-bar controller data attribute" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-controller='save-bar']")
    end

    it "includes tab name value" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-tab-name-value='partner_tabs']")
    end

    it "includes settings hash value" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-settings-hash-value='settings']")
    end

    it "includes preview hash value" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-preview-hash-value='preview']")
    end

    it "includes storage key value" do
      render_inline(described_class.new(**multi_step_params))
      expect(page).to have_css("[data-save-bar-storage-key-value='partnerTabAfterSave']")
    end
  end

  describe "#multi_step?" do
    it "returns true when multi_step is set" do
      component = described_class.new(multi_step: true)
      expect(component.multi_step?).to be true
    end

    it "returns false by default" do
      component = described_class.new
      expect(component.multi_step?).to be false
    end
  end

  describe "#stimulus_data_attributes" do
    it "returns empty hash when not multi-step" do
      component = described_class.new
      expect(component.stimulus_data_attributes).to eq({})
    end

    it "includes controller and all values when multi-step" do
      component = described_class.new(
        multi_step: true,
        tab_name: "tabs",
        settings_hash: "settings"
      )
      attrs = component.stimulus_data_attributes
      expect(attrs[:controller]).to eq("save-bar")
      expect(attrs["save-bar-tab-name-value"]).to eq("tabs")
      expect(attrs["save-bar-settings-hash-value"]).to eq("settings")
    end
  end
end
