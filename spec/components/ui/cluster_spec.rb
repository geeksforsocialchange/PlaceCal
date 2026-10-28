# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Cluster, type: :component do
  it "renders its children in order inside a div" do
    render_inline(described_class.new) { "<a href='/a'>A</a><a href='/b'>B</a>".html_safe }

    expect(page.all("div > a").map(&:text)).to eq(%w[A B])
  end

  it "renders as a list when asked" do
    render_inline(described_class.new(as: :ul)) { "<li>One</li><li>Two</li>".html_safe }

    expect(page).to have_css("ul > li", count: 2)
  end

  it "passes other attributes through" do
    render_inline(described_class.new(as: :nav, aria: { label: "Filters" })) { "x" }

    expect(page).to have_css("nav[aria-label='Filters']")
  end

  it "rejects a gap off the scale" do
    expect { described_class.new(gap: :huge) }.to raise_error(Literal::TypeError)
  end
end
