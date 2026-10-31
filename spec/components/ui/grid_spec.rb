# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Grid, type: :component do
  it "renders its children in order inside a div" do
    render_inline(described_class.new(cols: { md: 2, lg: 3 })) { "<p>One</p><p>Two</p>".html_safe }

    expect(page.all("div > p").map(&:text)).to eq(%w[One Two])
  end

  it "sets a column count for each breakpoint given" do
    render_inline(described_class.new(cols: { md: 2, lg: 3 })) { "x" }

    expect(page.find("div")[:class].split).to include("md:grid-cols-2", "lg:grid-cols-3")
    expect(page.find("div")[:class]).not_to match(/(?<!:)grid-cols-/)
  end

  it "renders as a list when asked" do
    render_inline(described_class.new(cols: { md: 2 }, as: :ul)) { "<li>One</li><li>Two</li>".html_safe }

    expect(page).to have_css("ul > li", count: 2)
  end

  it "rejects a column count or gap off the scale" do
    expect { described_class.new(cols: { md: 7 }) }.to raise_error(Literal::TypeError)
    expect { described_class.new(cols: { xxl: 2 }) }.to raise_error(Literal::TypeError)
    expect { described_class.new(cols: { md: 2 }, gap: :huge) }.to raise_error(Literal::TypeError)
  end
end
