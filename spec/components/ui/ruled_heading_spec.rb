# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::RuledHeading, type: :component do
  it "renders the heading level it is given with its attributes" do
    render_inline(described_class.new(level: 3, caps: true, id: "opening-times")) { "Opening times" }

    expect(page).to have_css("h3#opening-times", text: "Opening times")
  end

  it "rejects an unknown rule width" do
    expect { described_class.new(rule: :half) }.to raise_error(Literal::TypeError)
  end

  it "spaces itself from a preset" do
    render_inline(described_class.new(spacing: :illustrated)) { "Free wifi" }

    expect(page).to have_css("h2.mt-8.mb-6")
  end

  it "rejects a spacing that isn't one of its presets" do
    expect { described_class.new(spacing: :huge) }.to raise_error(Literal::TypeError)
  end
end
