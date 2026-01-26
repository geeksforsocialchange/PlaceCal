# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImpactStoryComponent, type: :component do
  let(:attrs) do
    {
      title: "We made organising community festivals a breeze",
      image: "http://example.com/image.jpg",
      image_caption: "Festival photo credit"
    }
  end

  it "renders title" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("We made organising community festivals a breeze")
  end

  it "renders image" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css("img[src='http://example.com/image.jpg']")
  end

  it "renders image caption" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("Festival photo credit")
  end

  it "renders block content" do
    render_inline(described_class.new(**attrs)) do
      "<p>Impact story content</p>".html_safe
    end

    expect(page).to have_text("Impact story content")
  end

  it "renders card structure" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css(".card__body")
    expect(page).to have_css("figure")
    expect(page).to have_css("figcaption")
  end
end
