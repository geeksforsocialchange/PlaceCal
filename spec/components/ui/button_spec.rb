# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Button, type: :component do
  describe "element" do
    it "renders a link when given an href" do
      render_inline(described_class.new(variant: :dark, href: "/events")) { "All events" }

      expect(page).to have_link("All events", href: "/events")
      expect(page).not_to have_css("button")
    end

    it "marks links with-no-sass so the legacy link colour does not apply" do
      render_inline(described_class.new(variant: :dark, href: "/events")) { "All events" }

      expect(page).to have_css("a.with-no-sass")
    end

    it "renders a type=button button without an href" do
      render_inline(described_class.new(variant: :outline)) { "Copy" }

      expect(page).to have_css("button[type='button']", text: "Copy")
      expect(page).not_to have_css("a")
      expect(page).not_to have_css(".with-no-sass")
    end

    it "takes a submit type" do
      render_inline(described_class.new(variant: :primary, type: "submit")) { "Search" }

      expect(page).to have_css("button[type='submit']", text: "Search")
    end

    it "renders markup from the block, such as an icon" do
      component = described_class.new(variant: :dark, href: "/partners")
      render_inline(component) { component.span(class: "icon") { "→" } }

      expect(page).to have_css("a span.icon", text: "→")
    end
  end

  describe "classes" do
    it "defaults to the medium pill" do
      render_inline(described_class.new(variant: :outline)) { "Go" }

      expect(page).to have_css("button.rounded-pill.py-2.px-5.text-detail")
    end

    it "applies the variant colours" do
      render_inline(described_class.new(variant: :dark_outline, size: :lg)) { "Go" }

      expect(page).to have_css("button.bg-transparent.border-foreground.text-base")
    end

    it "squares the field shape and sets its height" do
      render_inline(described_class.new(variant: :dark, size: :sm, shape: :field)) { "Apply" }

      expect(page).to have_css("button.rounded-sm")
      expect(page.find("button")[:class]).to include("h-(--height-field)")
      expect(page).not_to have_css("button.rounded-pill")
      expect(page).not_to have_css("button.py-1\\.5")
    end

    it "keeps extra classes alongside its own" do
      render_inline(described_class.new(variant: :join, href: "/demo", class: "mt-4")) { "Book a demo" }

      expect(page).to have_css("a.bg-secondary-strong.mt-4")
    end

    it "rejects an unknown variant" do
      expect { described_class.new(variant: :ghost) }.to raise_error(Literal::TypeError)
    end
  end

  describe "pass-through attributes" do
    it "renders data, aria, id and target attributes" do
      render_inline(described_class.new(variant: :outline, href: "https://example.org", id: "visit",
                                        target: "_blank", data: { copy_target: "button" },
                                        aria: { label: "Visit site" })) { "Visit" }

      link = page.find("a#visit")
      expect(link[:target]).to eq("_blank")
      expect(link["data-copy-target"]).to eq("button")
      expect(link["aria-label"]).to eq("Visit site")
    end
  end
end
