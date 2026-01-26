# frozen_string_literal: true

require "rails_helper"

RSpec.describe AudienceComponent, type: :component do
  let(:attrs) do
    {
      title: "Community groups",
      image: "home/audiences/communities_square.jpg",
      image_alt: "Community group activity",
      body: "Convert your local knowledge into a great community website."
    }
  end

  it "renders title" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("Community groups")
  end

  it "renders body text" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_text("Convert your local knowledge")
  end

  it "renders image with alt text" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css("img[alt='Community group activity']")
  end

  it "renders card structure" do
    render_inline(described_class.new(**attrs))

    expect(page).to have_css(".card.card--audience")
    expect(page).to have_css(".card__title")
    expect(page).to have_css(".card__body")
  end
end
