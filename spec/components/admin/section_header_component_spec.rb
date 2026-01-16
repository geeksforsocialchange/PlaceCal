# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SectionHeaderComponent, type: :component do
  it "renders title as h2 by default" do
    render_inline(described_class.new(title: "Basic Information"))
    expect(page).to have_css("h2.text-lg.font-bold", text: "Basic Information")
  end

  it "renders description when provided" do
    render_inline(described_class.new(
                    title: "Location",
                    description: "Where this partner is located."
                  ))
    expect(page).to have_css("p.text-sm", text: "Where this partner is located.")
  end

  it "does not render description paragraph when not provided" do
    render_inline(described_class.new(title: "Title Only"))
    expect(page).not_to have_css("p")
  end

  it "uses mb-6 for description by default" do
    render_inline(described_class.new(title: "Title", description: "Desc"))
    expect(page).to have_css("p.mb-6")
  end

  it "allows custom margin" do
    render_inline(described_class.new(title: "Title", description: "Desc", margin: 4))
    expect(page).to have_css("p.mb-4")
  end

  it "renders as h3 when specified" do
    render_inline(described_class.new(title: "Subsection", tag: :h3))
    expect(page).to have_css("h3.text-lg.font-bold", text: "Subsection")
  end

  describe "icon slot" do
    it "renders icon when provided" do
      render_inline(described_class.new(title: "Calendars")) do |c|
        c.with_icon { "<span class='icon'>📅</span>".html_safe }
      end
      expect(page).to have_css("h2 .icon", text: "📅")
    end

    it "adds flex classes when icon is present" do
      render_inline(described_class.new(title: "With Icon")) do |c|
        c.with_icon { "🔧" }
      end
      expect(page).to have_css("h2.flex.items-center.gap-2")
    end

    it "does not add flex classes when no icon" do
      render_inline(described_class.new(title: "No Icon"))
      expect(page).not_to have_css("h2.flex")
    end
  end
end
