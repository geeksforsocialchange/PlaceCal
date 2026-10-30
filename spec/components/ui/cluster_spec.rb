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

  it "lines its items up at the bottom" do
    render_inline(described_class.new(align: :end)) { "x" }

    expect(page).to have_css("div.flex.items-end")
  end

  it "justifies only from the breakpoint it is given" do
    render_inline(described_class.new(justify: :end, justify_from: :xl)) { "x" }

    expect(page).to have_css("div.xl\\:justify-end")
    expect(page).to have_no_css("div.justify-end")
  end

  it "stops wrapping from the breakpoint it is given" do
    render_inline(described_class.new(nowrap_from: :lg)) { "x" }

    expect(page).to have_css("div.flex-wrap.lg\\:flex-nowrap")
  end

  it "rejects a breakpoint it has no classes for" do
    expect { described_class.new(justify_from: :sm) }.to raise_error(Literal::TypeError)
  end

  it "rejects a gap off the scale" do
    expect { described_class.new(gap: :huge) }.to raise_error(Literal::TypeError)
  end
end
