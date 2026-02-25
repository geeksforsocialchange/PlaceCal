# frozen_string_literal: true

require "rails_helper"

RSpec.describe DetailsComponent, type: :component do
  let(:attrs) do
    {
      header: "The header value",
      summary: "The summary value",
      header_class: "the-header-class",
      header_level: 1,
      image_url: "home/our_story/collective_ownership.png",
      image_alt: "The image alt text",
      image_layout: "invalid-value"
    }
  end

  it "renders header" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector("h1")
    expect(page).to have_text("The header value")
  end

  it "renders summary" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector(".details-summary")
  end

  it "renders image alt text" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector('img[alt="The image alt text"]')
  end

  it "renders detail" do
    render_inline(described_class.new(**attrs)) do
      "The detail value"
    end

    expect(page).to have_text("The detail value")
    expect(page).to have_selector(".details-detail")
  end

  it "renders fallback layout" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector(".details-image-right")
  end
end
