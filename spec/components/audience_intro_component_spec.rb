# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudienceIntroComponent, type: :component do
  let(:attrs) do
    {
      title: "How we help community groups",
      subtitle: "We turn your local knowledge into great websites",
      image: "communities_wide.jpg",
      image_alt: "People enjoying a pottery class"
    }
  end

  it "renders title" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("How we help community groups")
  end

  it "renders subtitle" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("We turn your local knowledge")
  end

  it "renders image with alt text" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css("img[alt='People enjoying a pottery class']")
  end

  it "renders block content" do
    render_inline(described_class.new(**attrs)) do
      "<p>Block content here</p>".html_safe
    end

    expect(page).to have_text("Block content here")
  end

  it "renders card structure" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css(".card.card--first")
    expect(page).to have_css(".audience")
  end
end
