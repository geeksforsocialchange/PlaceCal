# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Sites::HeroSection, type: :phlex do
  it "hides a decorative image from screen readers" do
    render_inline(described_class.new(image_path: "/hero.jpg"))
    expect(page).to have_css("img[aria-hidden='true']", visible: :all)
  end

  it "shows the alt text and credit when given" do
    render_inline(described_class.new(image_path: "/hero.jpg", alttext: "A park", image_credit: "Sam"))
    expect(page).to have_css("img[alt='A park']")
    expect(page).to have_text("Image credit: Sam")
  end

  it "loads the image first, offering the smaller size to narrow screens" do
    render_inline(described_class.new(image_path: "/hero.jpg", image_srcset: "/standard_hero.jpg 1130w, /hero.jpg 2260w"))
    img = page.find("img", visible: :all)
    expect(img[:fetchpriority]).to eq("high")
    expect(img[:srcset]).to include("/standard_hero.jpg 1130w")
    expect([img[:width], img[:height]]).to eq(%w[2260 700])
  end

  it "falls back to its own heading, not the search description" do
    render_inline(described_class.new)
    expect(page).to have_css("h1", text: "PlaceCal is a community events calendar where you can find out everything that's happening, all in one place.")
  end
end
