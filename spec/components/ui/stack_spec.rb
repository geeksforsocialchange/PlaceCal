# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Stack, type: :component do
  it "renders its children in order inside a div" do
    render_inline(described_class.new) { "<h2>Title</h2><p>Body</p>".html_safe }

    expect(page.all("div > *").map(&:text)).to eq(%w[Title Body])
  end

  it "renders as a section when asked" do
    render_inline(described_class.new(as: :section, aria: { labelledby: "times" })) { "x" }

    expect(page).to have_css("section[aria-labelledby='times']")
  end

  it "rejects a gap off the scale" do
    expect { described_class.new(gap: :huge) }.to raise_error(Literal::TypeError)
  end
end
