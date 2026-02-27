# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Navigation, type: :component do
  let(:navigation) { [["Events", "/events"], ["Partners", "/partners"]] }

  it "renders navigation links" do
    render_inline(described_class.new(navigation: navigation))

    expect(page).to have_link("Events", href: "/events")
    expect(page).to have_link("Partners", href: "/partners")
  end

  it "renders home link" do
    render_inline(described_class.new(navigation: navigation))

    expect(page).to have_link("Home")
  end

  it "renders header structure" do
    render_inline(described_class.new(navigation: navigation))

    expect(page).to have_css(".header")
    expect(page).to have_css("nav.nav")
  end

  it "handles empty navigation" do
    render_inline(described_class.new(navigation: []))

    expect(page).to have_link("Home")
  end
end
