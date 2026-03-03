# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::SectionHeader, type: :phlex do
  it "renders title as h2 by default" do
    render_inline(described_class.new(title: "Section Title"))
    expect(page).to have_css("h2", text: "Section Title")
  end

  it "renders description when provided" do
    render_inline(described_class.new(title: "Title", description: "A description"))
    expect(page).to have_text("A description")
    expect(page).to have_css("p.text-sm")
  end

  it "does not render description when not provided" do
    render_inline(described_class.new(title: "Title"))
    expect(page).not_to have_css("p")
  end

  it "allows custom heading tags" do
    render_inline(described_class.new(title: "Title", tag: :h3))
    expect(page).to have_css("h3", text: "Title")
  end
end
