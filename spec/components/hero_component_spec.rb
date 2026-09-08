# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Hero, type: :component do
  it "renders the tagline as a paragraph rather than a heading" do
    render_inline(described_class.new("Riverside Hub", "Events in Riverside"))

    expect(page).to have_css("p.allcaps", text: "Events in Riverside")
    expect(page).not_to have_css("h4")
  end

  it "adds no heading above the h1, so the site name h2 stays the last one before it" do
    render_inline(described_class.new("Riverside Hub", "Events in Riverside", section: "Partner"))

    headings = page.all("h1, h2, h3, h4, h5, h6").map(&:tag_name)

    expect(headings).to eq(["h1"])
  end

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

  # Optional back link (#3368): "All events" above an event page hero, say.
  describe "the back link" do
    it "renders nothing when back is not given" do
      render_inline(described_class.new("Riverside Hub", nil))

      expect(page).not_to have_css("a.hero__back")
    end

    it "renders the label and path when back is given" do
      render_inline(described_class.new("Riverside Hub", nil, back: ["All events", "/events"]))

      expect(page).to have_link("All events", href: "/events", class: "hero__back")
    end

    it "renders above the section name and the title" do
      render_inline(described_class.new("Riverside Hub", nil, section: "Partner", back: ["All partners", "/partners"]))

      order = page.all("a.hero__back, p.hero__section, h1").map(&:tag_name)

      expect(order).to eq(%w[a p h1])
    end
  end
end
