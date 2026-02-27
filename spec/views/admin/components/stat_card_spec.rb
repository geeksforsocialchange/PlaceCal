# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Components::StatCard, type: :phlex do
  it "renders label and value" do
    render_inline(described_class.new(label: "Users", value: 42))
    expect(page).to have_text("Users")
    expect(page).to have_text("42")
  end

  it "renders value prominently" do
    render_inline(described_class.new(label: "Users", value: 42))
    expect(page).to have_css(".text-2xl.font-bold", text: "42")
  end

  it "renders icon when provided" do
    render_inline(described_class.new(label: "Users", value: 42, icon: :users))
    expect(page).to have_css("svg")
  end

  it "renders subtitle when provided" do
    render_inline(described_class.new(label: "Users", value: 42, subtitle: "Active"))
    expect(page).to have_text("Active")
  end

  it "prefers subtitle over icon" do
    render_inline(described_class.new(label: "Users", value: 42, icon: :users, subtitle: "Active"))
    expect(page).to have_text("Active")
  end

  it "accepts block content" do
    render_inline(described_class.new(label: "Users", value: 42)) { "Extra content" }
    expect(page).to have_text("Extra content")
  end
end
