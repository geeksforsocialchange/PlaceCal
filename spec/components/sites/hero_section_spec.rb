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
end
