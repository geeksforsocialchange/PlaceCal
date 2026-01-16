# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CardComponent, type: :component do
  it "renders basic card with content" do
    render_inline(described_class.new) { "Card content" }
    expect(page).to have_css(".card")
    expect(page).to have_text("Card content")
  end

  it "renders with title" do
    render_inline(described_class.new(title: "My Card")) { "Content" }
    expect(page).to have_css("h2.font-bold", text: "My Card")
  end

  it "renders with icon when provided" do
    render_inline(described_class.new(title: "Card", icon: :calendar)) { "Content" }
    expect(page).to have_css("svg") # icon rendered
  end

  describe "variants" do
    it "renders default variant" do
      render_inline(described_class.new(variant: :default)) { "Content" }
      expect(page).to have_css(".card.bg-base-100.border-base-300")
    end

    it "renders success variant" do
      render_inline(described_class.new(variant: :success)) { "Content" }
      expect(page).to have_css(".card.bg-success\\/5.border-success\\/20")
    end

    it "renders error variant" do
      render_inline(described_class.new(variant: :error)) { "Content" }
      expect(page).to have_css(".card.bg-error\\/5.border-error\\/20")
    end

    it "renders warning variant" do
      render_inline(described_class.new(variant: :warning)) { "Content" }
      expect(page).to have_css(".card.bg-warning\\/5.border-warning\\/20")
    end

    it "renders orange variant with gradient" do
      render_inline(described_class.new(variant: :orange)) { "Content" }
      expect(page).to have_css(".card.bg-gradient-to-br")
    end
  end

  describe "header slots" do
    it "renders custom header when provided" do
      component = described_class.new
      render_inline(component) do |c|
        c.with_header { "<span class='custom-header'>Custom</span>".html_safe }
        "Body"
      end
      expect(page).to have_css(".custom-header", text: "Custom")
    end

    it "renders header action when provided" do
      component = described_class.new(title: "Card")
      render_inline(component) do |c|
        c.with_header_action { "<button class='action-btn'>Action</button>".html_safe }
        "Body"
      end
      expect(page).to have_css(".action-btn", text: "Action")
    end

    it "renders header link when provided" do
      render_inline(described_class.new(
                      title: "Card",
                      header_link: "/test",
                      header_link_text: "View All"
                    )) { "Content" }
      expect(page).to have_link("View All", href: "/test")
    end
  end

  describe "body slot" do
    it "renders body slot content" do
      component = described_class.new
      render_inline(component) do |c|
        c.with_body { "<div class='custom-body'>Body content</div>".html_safe }
      end
      expect(page).to have_css(".custom-body", text: "Body content")
    end
  end

  describe "decorative blur" do
    it "renders blur element when decorative_blur is set" do
      render_inline(described_class.new(variant: :orange, decorative_blur: :top_right)) { "Content" }
      expect(page).to have_css(".blur-2xl")
    end

    it "positions blur at top right" do
      render_inline(described_class.new(variant: :orange, decorative_blur: :top_right)) { "Content" }
      expect(page).to have_css(".-right-8.-top-8")
    end

    it "positions blur at bottom left" do
      render_inline(described_class.new(variant: :orange, decorative_blur: :bottom_left)) { "Content" }
      expect(page).to have_css(".-left-8.-bottom-8")
    end
  end
end
