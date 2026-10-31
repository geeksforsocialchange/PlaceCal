# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Stat, type: :component do
  it "renders the value before its label" do
    render_inline(described_class.new(value: "1,234", label: "Partners"))

    expect(page.all("div > span").map(&:text)).to eq(["1,234", "Partners"])
  end

  it "rejects a value that isn't already formatted" do
    expect { described_class.new(value: 1234, label: "Partners") }.to raise_error(Literal::TypeError)
  end
end
