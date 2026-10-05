# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Directory::ToggleTabs, type: :component do
  let(:items) do
    [
      { label: "This week", href: "/events?period=week", active: true },
      { label: "Today", href: "/events?period=day", active: false }
    ]
  end

  it "renders the active item as a static pill, not a link" do
    render_inline(described_class.new(items: items, aria_label: "Time period"))

    expect(page).to have_css("span", text: "This week")
    expect(page).to have_no_link("This week")
  end

  it "renders inactive items as links" do
    render_inline(described_class.new(items: items, aria_label: "Time period"))

    expect(page).to have_link("Today", href: "/events?period=day")
  end

  it "labels the nav landmark" do
    render_inline(described_class.new(items: items, aria_label: "Time period"))

    expect(page).to have_css("nav[aria-label='Time period']")
  end
end
