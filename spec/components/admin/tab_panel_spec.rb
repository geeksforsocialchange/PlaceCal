# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::TabPanel, type: :phlex do
  let(:default_attrs) do
    {
      name: "my_tabs",
      label: "Basic Info",
      hash: "basic",
      controller_name: "form-tabs"
    }
  end

  it "renders radio input" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css("input[type='radio'][name='my_tabs']")
  end

  it "sets aria-label" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css("input[aria-label='Basic Info']")
  end

  it "sets data-hash attribute" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css("input[data-hash='basic']")
  end

  it "renders panel content" do
    render_inline(described_class.new(**default_attrs)) { "Panel content" }
    expect(page).to have_text("Panel content")
  end

  it "marks as checked when specified" do
    render_inline(described_class.new(**default_attrs, checked: true))
    expect(page).to have_css("input[checked='checked']")
  end

  it "renders panel with correct styling" do
    render_inline(described_class.new(**default_attrs))
    expect(page).to have_css(".tab-content.bg-base-100")
  end
end
