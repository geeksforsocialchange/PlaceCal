# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::AzJumpBar, type: :component do
  it "links letters that have partners and disables the rest" do
    render_inline(described_class.new(active_letters: Set["A", "C"]))

    expect(page).to have_link("A", href: "/partners?letter=A&sort=name")
    expect(page).to have_css("span[data-variant='letter']", text: "B")
    expect(page).to have_no_link("B")
  end

  it "selects All when no letter is chosen" do
    render_inline(described_class.new(active_letters: Set["A"]))

    expect(page).to have_css("span[aria-current='page']", text: "All")
    expect(page).to have_link("A")
  end

  it "selects the chosen letter and links All back to every partner" do
    render_inline(described_class.new(active_letters: Set["A"], selected_letter: "A", filter_params: { "category" => "1" }))

    expect(page).to have_css("span[aria-current='page']", text: "A")
    expect(page).to have_link("All", href: "/partners?category=1&sort=name")
  end
end
