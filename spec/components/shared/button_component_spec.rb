# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Shared::Button, type: :component do
  describe "element" do
    it "renders a link when given an href" do
      render_inline(described_class.new(variant: :dark, href: "/events")) { "All events" }

      expect(page).to have_link("All events", href: "/events")
      expect(page).not_to have_css("button")
    end

    it "marks links with-no-sass so the legacy link colour does not apply" do
      render_inline(described_class.new(variant: :dark, href: "/events")) { "All events" }

      expect(page).to have_css("a.with-no-sass.button")
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

      expect(page).to have_css("a.button span.icon", text: "→")
    end
  end

  describe "classes" do
    it "defaults to the medium pill" do
      render_inline(described_class.new(variant: :outline)) { "Go" }

      expect(page).to have_css("button.button.button--outline.button--md")
      expect(page).not_to have_css(".button--field")
    end

    it "dasherizes the variant and applies the size" do
      render_inline(described_class.new(variant: :dark_outline, size: :lg)) { "Go" }

      expect(page).to have_css("button.button--dark-outline.button--lg")
    end

    it "adds the field shape" do
      render_inline(described_class.new(variant: :dark, size: :sm, shape: :field)) { "Apply" }

      expect(page).to have_css("button.button--dark.button--sm.button--field")
    end

    it "keeps extra classes alongside its own" do
      render_inline(described_class.new(variant: :join, href: "/demo", class: "mt-4")) { "Book a demo" }

      expect(page).to have_css("a.button.button--join.mt-4")
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

  describe ".classes" do
    it "returns the class string for form helpers" do
      expect(described_class.classes(variant: :dark)).to eq("button button--dark button--md")
    end

    it "includes size and shape" do
      expect(described_class.classes(variant: :dark_outline, size: :sm, shape: :field))
        .to eq("button button--dark-outline button--sm button--field")
    end

    it "raises on an unknown variant" do
      expect { described_class.classes(variant: :ghost) }.to raise_error(ArgumentError)
    end
  end
end
