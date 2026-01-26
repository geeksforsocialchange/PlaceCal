# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::TabPanelComponent, type: :component do
  it "renders radio input with correct name" do
    render_inline(described_class.new(
                    name: "partner_tabs",
                    label: "📋 Basic Info",
                    hash: "basic",
                    controller_name: "partner-tabs"
                  )) { "Tab content" }
    expect(page).to have_css("input[type='radio'][name='partner_tabs']")
  end

  it "renders aria-label" do
    render_inline(described_class.new(
                    name: "site_tabs",
                    label: "🖼️ Images",
                    hash: "images",
                    controller_name: "site-tabs"
                  )) { "Content" }
    expect(page).to have_css("input[aria-label='🖼️ Images']")
  end

  it "renders data-hash attribute" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "settings",
                    controller_name: "my-tabs"
                  )) { "Content" }
    expect(page).to have_css("input[data-hash='settings']")
  end

  it "renders Stimulus target for tab" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "test",
                    controller_name: "calendar-tabs"
                  )) { "Content" }
    expect(page).to have_css("input[data-calendar-tabs-target='tab']")
  end

  it "renders Stimulus target for panel" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "test",
                    controller_name: "partner-tabs"
                  )) { "Content" }
    expect(page).to have_css("div[data-partner-tabs-target='panel']")
  end

  it "renders data-section on panel" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "location",
                    controller_name: "tabs"
                  )) { "Content" }
    expect(page).to have_css("div[data-section='location']")
  end

  it "renders content inside panel" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "test",
                    controller_name: "tabs"
                  )) { "<p class='inner'>Inner content</p>".html_safe }
    expect(page).to have_css(".tab-content .inner", text: "Inner content")
  end

  describe "checked attribute" do
    it "adds checked when checked: true" do
      render_inline(described_class.new(
                      name: "tabs",
                      label: "Label",
                      hash: "test",
                      controller_name: "tabs",
                      checked: true
                    )) { "Content" }
      expect(page).to have_css("input[type='radio'][checked]")
    end

    it "does not add checked by default" do
      render_inline(described_class.new(
                      name: "tabs",
                      label: "Label",
                      hash: "test",
                      controller_name: "tabs"
                    )) { "Content" }
      expect(page).not_to have_css("input[type='radio'][checked]")
    end
  end

  it "renders with correct panel styling" do
    render_inline(described_class.new(
                    name: "tabs",
                    label: "Label",
                    hash: "test",
                    controller_name: "tabs"
                  )) { "Content" }
    expect(page).to have_css(".tab-content.bg-base-100.border-base-300.p-6")
  end
end
