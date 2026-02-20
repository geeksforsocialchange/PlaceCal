# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::EmptyStateComponent, type: :component do
  it "renders with icon and message" do
    render_inline(described_class.new(icon: :calendar, message: "No events found"))
    expect(page).to have_css("svg") # icon rendered
    expect(page).to have_text("No events found")
  end

  it "renders hint text when provided" do
    render_inline(described_class.new(
                    icon: :partner,
                    message: "No partners yet",
                    hint: "Add a partner to get started"
                  ))
    expect(page).to have_text("No partners yet")
    expect(page).to have_text("Add a partner to get started")
  end

  it "does not render hint when not provided" do
    render_inline(described_class.new(icon: :calendar, message: "No events"))
    expect(page).to have_css("p", count: 1) # only the message, not hint
  end

  it "uses default padding" do
    render_inline(described_class.new(icon: :calendar, message: "Empty"))
    expect(page).to have_css(".py-8")
  end

  it "allows custom padding" do
    render_inline(described_class.new(icon: :calendar, message: "Empty", padding: "py-12"))
    expect(page).to have_css(".py-12")
  end

  it "uses default icon size" do
    render_inline(described_class.new(icon: :calendar, message: "Empty"))
    # Default size is 10, which adds size-10 class
    expect(page).to have_css("svg.size-10")
  end

  it "allows custom icon size" do
    render_inline(described_class.new(icon: :calendar, message: "Empty", icon_size: "12"))
    expect(page).to have_css("svg.size-12")
  end
end
