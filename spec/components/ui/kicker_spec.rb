# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Kicker, type: :component do
  it "renders an allcaps label in a div by default" do
    render_inline(described_class.new(tone: :muted)) { "Our partnerships" }

    expect(page).to have_css("div.allcaps-label.text-tertiary", text: "Our partnerships")
  end

  it "renders as the element it is given" do
    render_inline(described_class.new(as: :h3, id: "times")) { "Opening times" }

    expect(page).to have_css("h3#times.allcaps-label", text: "Opening times")
  end

  it "rejects a tone it doesn't have" do
    expect { described_class.new(tone: :loud) }.to raise_error(Literal::TypeError)
  end

  it "rejects a spacing that isn't one of the heading steps" do
    expect { described_class.new(spacing: :huge) }.to raise_error(Literal::TypeError)
  end
end
