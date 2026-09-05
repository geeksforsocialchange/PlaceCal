# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Hero, type: :component do
  it "escapes markup in the title" do
    render_inline(described_class.new("<img src=x onerror=1> Garden", "Partner"))

    expect(page).to have_css("h1", text: "<img src=x onerror=1> Garden")
    expect(page).not_to have_css("h1 img")
  end

  it "breaks a long title across two lines with a real br element" do
    render_inline(described_class.new("A rather long partner name that needs splitting", nil))

    expect(page).to have_css("h1 br", count: 1)
    expect(page).to have_css("h1", text: "A rather long partner name that needs splitting")
  end

  it "escapes markup in a long title too" do
    render_inline(described_class.new("<b>bold</b> and a long title here to trip the split path", nil))

    expect(page).not_to have_css("h1 b")
    expect(page).to have_css("h1", text: "<b>bold</b>")
  end
end
