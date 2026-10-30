# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::CircleBadge, type: :component do
  it "renders its label" do
    render_inline(described_class.new) { "AB" }

    expect(page).to have_css("div.rounded-full", text: "AB")
  end

  it "takes a different size from the md breakpoint" do
    render_inline(described_class.new(size: :sm, md_size: :lg)) { "1" }

    expect(page.find("div")[:class].split).to include("size-11", "md:size-14")
  end

  it "passes other attributes through" do
    render_inline(described_class.new(title: "Riverside Hub")) { "RH" }

    expect(page).to have_css("div[title='Riverside Hub']")
  end

  it "rejects a size or tone off the scale" do
    expect { described_class.new(size: :xl) }.to raise_error(Literal::TypeError)
    expect { described_class.new(tone: :primary) }.to raise_error(Literal::TypeError)
  end
end
