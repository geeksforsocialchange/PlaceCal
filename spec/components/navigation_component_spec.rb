# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Navigation, type: :component do
  let(:navigation) { [["Home", "/"], ["Events", "/events"], ["Partners", "/partners"]] }

  it "renders navigation links" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_link("Events", href: "/events")
    expect(page).to have_link("Partners", href: "/partners")
  end

  it "renders home link" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_link("Home")
  end

  it "renders header structure" do
    render_inline(described_class.new(navigation: navigation, site: nil))

    expect(page).to have_css(".header")
    expect(page).to have_css("nav.nav")
  end

  describe "with a region selected" do
    let(:region_navigation) do
      [["Home", "/?region=north"], ["Events", "/events?region=north"], ["Partners", "/partners?region=north"]]
    end

    it "keeps the region param on every site link" do
      render_inline(described_class.new(navigation: region_navigation, site: nil))

      expect(page).to have_link("Home", href: "/?region=north")
      expect(page).to have_link("Events", href: "/events?region=north")
      expect(page).to have_link("Partners", href: "/partners?region=north")
    end
  end
end
