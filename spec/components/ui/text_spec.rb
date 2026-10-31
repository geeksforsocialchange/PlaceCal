# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Text, type: :component do
  it "renders a body paragraph by default" do
    render_inline(described_class.new) { "PlaceCal is a community events calendar." }

    expect(page).to have_css("p.text-base.leading-relaxed", text: "PlaceCal is a community events calendar.")
  end

  it "sets the tone and measure it is given" do
    render_inline(described_class.new(variant: :lede, tone: :muted, measure: :prose)) { "A short lede." }

    expect(page).to have_css("p.text-detail.text-tertiary[class*='max-w-']", text: "A short lede.")
  end

  it "renders as the element it is given" do
    render_inline(described_class.new(as: :figcaption)) { "Caption" }

    expect(page).to have_css("figcaption", text: "Caption")
  end

  it "rejects a measure it doesn't have" do
    expect { described_class.new(measure: :wide) }.to raise_error(Literal::TypeError)
  end
end
