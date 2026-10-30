# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::Paginator, type: :component do
  def render_page(page, pages: 10)
    render_inline(described_class.new(pagy: Pagy::Offset.new(count: pages * 30, page:, limit: 30)))
  end

  it "marks the current page and links to the others" do
    render_page(5)

    expect(page).to have_css("span[aria-current='page']", text: "5")
    expect(page).to have_link("4")
    expect(page).to have_link("10")
    expect(page).not_to have_link("5")
  end

  it "has no previous link on the first page" do
    render_page(1)

    expect(page).not_to have_link("←")
    expect(page).to have_link("→")
  end

  it "renders nothing for a single page" do
    render_page(1, pages: 1)

    expect(page).not_to have_css("nav")
  end
end
