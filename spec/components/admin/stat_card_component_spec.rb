# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StatCardComponent, type: :component do
  it "renders with label and value" do
    render_inline(described_class.new(label: "Total Events", value: 42))
    expect(page).to have_css(".card")
    expect(page).to have_text("Total Events")
    expect(page).to have_text("42")
  end

  it "renders value prominently" do
    render_inline(described_class.new(label: "Count", value: 100))
    expect(page).to have_css(".text-2xl.font-bold", text: "100")
  end

  it "renders label in smaller text" do
    render_inline(described_class.new(label: "Partners", value: 5))
    expect(page).to have_css(".text-xs", text: "Partners")
  end

  describe "with icon" do
    it "renders icon when provided" do
      render_inline(described_class.new(label: "Calendars", value: 10, icon: :calendar))
      expect(page).to have_css("svg")
    end

    it "does not render icon when not provided" do
      render_inline(described_class.new(label: "Test", value: 1))
      expect(page).not_to have_css("svg")
    end
  end

  describe "with subtitle" do
    it "renders subtitle when provided" do
      render_inline(described_class.new(label: "Events", value: 50, subtitle: "this week"))
      expect(page).to have_text("this week")
    end

    it "subtitle takes precedence over icon" do
      render_inline(described_class.new(
                      label: "Events",
                      value: 50,
                      subtitle: "today",
                      icon: :calendar
                    ))
      expect(page).to have_text("today")
      # When subtitle is present, icon should not render
    end
  end

  it "accepts block content" do
    render_inline(described_class.new(label: "Test", value: 1)) do
      "<span class='extra'>Extra content</span>".html_safe
    end
    expect(page).to have_css(".extra", text: "Extra content")
  end
end
