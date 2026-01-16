# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FieldsetComponent, type: :component do
  it "renders with label" do
    render_inline(described_class.new(label: "Name")) { "<input type='text' />".html_safe }
    expect(page).to have_css("fieldset.fieldset")
    expect(page).to have_css("legend.fieldset-legend", text: "Name")
  end

  it "shows required indicator when required: true" do
    render_inline(described_class.new(label: "Email", required: true)) { "<input />".html_safe }
    expect(page).to have_css("legend .text-error", text: "*")
  end

  it "does not show required indicator when required: false" do
    render_inline(described_class.new(label: "Email", required: false)) { "<input />".html_safe }
    expect(page).not_to have_css(".text-error")
  end

  it "renders hint text when provided" do
    render_inline(described_class.new(label: "Name", hint: "Enter your full name")) { "<input />".html_safe }
    expect(page).to have_css(".fieldset-label", text: "Enter your full name")
  end

  it "does not render hint when not provided" do
    render_inline(described_class.new(label: "Name")) { "<input />".html_safe }
    expect(page).not_to have_css(".fieldset-label")
  end

  it "renders char counter when provided" do
    render_inline(described_class.new(label: "Summary", char_counter: 100)) { "<textarea></textarea>".html_safe }
    expect(page).to have_css("[data-controller='char-counter']")
    expect(page).to have_css("[data-char-counter-max-value='100']")
    expect(page).to have_css("[data-char-counter-target='display']", text: "0/100")
  end

  it "renders input slot content" do
    component = described_class.new(label: "Name")
    render_inline(component) do |c|
      c.with_input { "<input class='test-input' />".html_safe }
    end
    expect(page).to have_css("input.test-input")
  end
end
