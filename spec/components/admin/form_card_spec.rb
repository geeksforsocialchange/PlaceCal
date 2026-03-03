# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::FormCard, type: :phlex do
  it "renders with icon and title" do
    render_inline(described_class.new(icon: :map, title: "Address")) { "Fields here" }
    expect(page).to have_css("h2", text: "Address")
    expect(page).to have_css("svg")
    expect(page).to have_text("Fields here")
  end

  it "renders description when provided" do
    render_inline(described_class.new(icon: :clock, title: "Times", description: "When open?")) { "Content" }
    expect(page).to have_text("When open?")
  end

  it "does not render description when not provided" do
    render_inline(described_class.new(icon: :map, title: "Address")) { "Content" }
    expect(page).not_to have_css("p.text-xs.text-gray-600")
  end

  it "applies h-fit when fit_height is true" do
    render_inline(described_class.new(icon: :map, title: "Address", fit_height: true)) { "Content" }
    expect(page).to have_css(".h-fit")
  end
end
