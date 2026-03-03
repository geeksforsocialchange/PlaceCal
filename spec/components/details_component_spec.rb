# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Details, type: :phlex do
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

  it "renders a details element with summary" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector("details.details")
    expect(page).to have_selector("details summary")
  end

  it "renders header at the specified level" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector("h1.details__header")
    expect(page).to have_text("The header value")
  end

  it "applies custom header class" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector("h1.the-header-class")
  end

  it "defaults to h3 when no header_level specified" do
    render_inline(described_class.new(header: "Test", summary: "Summary"))

    expect(page).to have_selector("h3.details__header")
  end

  it "does not render header when nil" do
    render_inline(described_class.new(summary: "Summary only"))

    expect(page).to have_no_selector(".details__header")
    expect(page).to have_selector(".details__summary")
  end

  it "renders plain text summary in a paragraph" do
    render_inline(described_class.new(summary: "Plain text summary"))

    expect(page).to have_selector(".details__summary p", text: "Plain text summary")
  end

  it "renders html_safe summary without extra wrapper" do
    render_inline(described_class.new(summary: "<p>Already wrapped</p>".html_safe))

    expect(page).to have_selector(".details__summary p", text: "Already wrapped")
  end

  it "renders image with alt text" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector('img[alt="The image alt text"]')
  end

  it "does not render image when image_url is nil" do
    render_inline(described_class.new(summary: "No image"))

    expect(page).to have_no_selector("img")
  end

  it "renders toggle button with plus and minus icons" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_selector(".btn svg[data-icon-name='home_plus']")
    expect(page).to have_selector(".btn svg[data-icon-name='home_minus']")
    expect(page).to have_text("Open to read more")
    expect(page).to have_text("Close")
  end

  it "renders block content in details__detail div" do
    render_inline(described_class.new(**attrs)) do
      "The detail value"
    end

    expect(page).to have_selector(".details__detail", text: "The detail value")
  end

  it "does not render details__detail div when no block given" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_no_selector(".details__detail")
  end

  describe "image_layout" do
    it "falls back to right for invalid layout values" do
      render_inline(described_class.new(**attrs, image_layout: "invalid"))

      expect(page).to have_selector(".details__image__right")
    end

    it "uses specified layout when valid" do
      render_inline(described_class.new(**attrs, image_layout: "left"))

      expect(page).to have_selector(".details__image__left")
    end

    it "uses center layout" do
      render_inline(described_class.new(**attrs, image_layout: "center"))

      expect(page).to have_selector(".details__image__center")
    end

    it "uses none layout when no image_url" do
      render_inline(described_class.new(summary: "No image"))

      expect(page).to have_selector(".details__image__none")
    end
  end
end
