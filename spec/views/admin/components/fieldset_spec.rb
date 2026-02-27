# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Components::Fieldset, type: :phlex do
  it "renders with label" do
    render_inline(described_class.new(label: "Name")) { "Input here" }
    expect(page).to have_css("fieldset.fieldset")
    expect(page).to have_css("legend.fieldset-legend", text: "Name")
  end

  it "shows required indicator" do
    render_inline(described_class.new(label: "Name", required: true)) { "Input" }
    expect(page).to have_css(".text-error", text: "*")
  end

  it "renders hint text" do
    render_inline(described_class.new(label: "Name", hint: "Enter full name")) { "Input" }
    expect(page).to have_css(".fieldset-label", text: "Enter full name")
  end

  it "renders character counter" do
    render_inline(described_class.new(label: "Name", char_counter: 100)) { "Input" }
    expect(page).to have_css("[data-controller='char-counter']")
    expect(page).to have_text("0/100")
  end

  it "renders content block" do
    render_inline(described_class.new(label: "Name")) { "My content" }
    expect(page).to have_text("My content")
  end
end
