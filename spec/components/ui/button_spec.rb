# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Button, type: :component do
  it "renders a link when given an href" do
    render_inline(described_class.new(variant: :dark, href: "/events")) { "All events" }

    expect(page).to have_link("All events", href: "/events")
    expect(page).not_to have_css("button")
  end

  it "renders a button of the given type without an href" do
    render_inline(described_class.new(variant: :primary, type: "submit")) { "Search" }

    expect(page).to have_css("button[type='submit']", text: "Search")
    expect(page).not_to have_css("a")
  end

  it "renders markup from the block, such as an icon" do
    component = described_class.new(variant: :dark, href: "/partners")
    render_inline(component) { component.span(class: "icon") { "→" } }

    expect(page).to have_css("a span.icon", text: "→")
  end

  it "keeps extra classes alongside its own" do
    render_inline(described_class.new(variant: :join, href: "/demo", class: "mt-4")) { "Book a demo" }

    expect(page).to have_css("a.mt-4.rounded-pill")
  end

  it "passes data, aria, id and target attributes through" do
    render_inline(described_class.new(variant: :outline, href: "https://example.org", id: "visit",
                                      target: "_blank", data: { copy_target: "button" },
                                      aria: { label: "Visit site" })) { "Visit" }

    link = page.find("a#visit")
    expect(link[:target]).to eq("_blank")
    expect(link["data-copy-target"]).to eq("button")
    expect(link["aria-label"]).to eq("Visit site")
  end

  it "rejects an unknown variant" do
    expect { described_class.new(variant: :ghost) }.to raise_error(Literal::TypeError)
  end
end
