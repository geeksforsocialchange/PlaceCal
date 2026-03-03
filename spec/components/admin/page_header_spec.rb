# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::PageHeader, type: :phlex do
  it "renders heading for new record" do
    render_inline(described_class.new(model_name: "Calendar", new_record: true))
    expect(page).to have_css("h1", text: "New Calendar")
  end

  it "renders heading for edit record" do
    render_inline(described_class.new(model_name: "Partner", title: "Test Partner", id: 42))
    expect(page).to have_css("h1", text: "Edit Partner")
  end

  it "shows title text below heading when editing" do
    render_inline(described_class.new(model_name: "Partner", title: "Test Partner", id: 42))
    expect(page).to have_css("p.text-gray-600", text: "Test Partner")
  end

  it "does not show title text for new records" do
    render_inline(described_class.new(model_name: "Calendar", new_record: true))
    expect(page).not_to have_css("p.text-gray-600")
  end

  it "shows ID when provided" do
    render_inline(described_class.new(model_name: "Partner", title: "Test", id: 42))
    expect(page).to have_text("ID: 42")
  end

  it "does not show ID when not provided" do
    render_inline(described_class.new(model_name: "Calendar", new_record: true))
    expect(page).not_to have_text("ID:")
  end

  it "wraps content in a flex container" do
    render_inline(described_class.new(model_name: "Calendar", new_record: true))
    expect(page).to have_css("div.flex.items-center.justify-between.mb-6")
  end
end
