# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::EmptyState, type: :component do
  it "renders the message" do
    render_inline(described_class.new(message: "No partners found"))

    expect(page).to have_css("p", text: "No partners found")
  end

  it "renders a reset link when given both text and href" do
    render_inline(described_class.new(message: "No partners found", link_text: "Clear filters", link_href: "/partners"))

    expect(page).to have_link("Clear filters", href: "/partners")
  end

  it "omits the link when href is missing" do
    render_inline(described_class.new(message: "No partners found", link_text: "Clear filters"))

    expect(page).to have_no_link
  end
end
