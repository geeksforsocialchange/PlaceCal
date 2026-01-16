# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::NeighbourhoodHierarchyBadgeComponent, type: :component do
  let(:country) { create(:neighbourhood, name: "England", unit: "country", level: 5) }
  let(:region) { create(:neighbourhood, name: "London", unit: "region", level: 4, parent: country) }
  let(:county) { create(:neighbourhood, name: "Inner London", unit: "county", level: 3, parent: region) }
  let(:district) { create(:neighbourhood, name: "Hackney", unit: "district", level: 2, parent: county) }
  let(:ward) { create(:neighbourhood, name: "Hackney Central", unit: "ward", level: 1, parent: district) }

  describe "basic rendering" do
    it "renders the neighbourhood hierarchy" do
      render_inline(described_class.new(neighbourhood: ward))

      expect(page).to have_text("England")
      expect(page).to have_text("London")
      expect(page).to have_text("Hackney")
    end

    it "renders badges with level colours" do
      render_inline(described_class.new(neighbourhood: ward))

      # Check that coloured badges are present
      expect(page).to have_css(".bg-rose-100") # country
      expect(page).to have_css(".bg-orange-100") # region
    end
  end

  describe "with show_icons option" do
    it "renders level indicators when show_icons is true" do
      render_inline(described_class.new(neighbourhood: district, show_icons: true))

      expect(page).to have_text("L5") # country
      expect(page).to have_text("L4") # region
      expect(page).to have_text("L3") # county
      expect(page).to have_text("L2") # district (current)
    end

    it "does not render level indicators when show_icons is false" do
      render_inline(described_class.new(neighbourhood: district, show_icons: false))

      expect(page).not_to have_text("L5")
      expect(page).not_to have_text("L4")
    end
  end

  describe "with link_each option" do
    it "renders links when link_each is true" do
      render_inline(described_class.new(neighbourhood: ward, link_each: true))

      expect(page).to have_link("England")
      expect(page).to have_link("London")
    end

    it "renders spans when link_each is false" do
      render_inline(described_class.new(neighbourhood: ward, link_each: false))

      expect(page).not_to have_link("England")
      expect(page).to have_text("England")
    end
  end

  describe "with max_levels option" do
    it "truncates hierarchy when max_levels is set" do
      render_inline(described_class.new(neighbourhood: ward, max_levels: 2, truncate: true))

      # Should only show last 2 levels (district and ward)
      expect(page).to have_text("Hackney")
      expect(page).to have_text("Hackney Central")
      # Should not show country
      expect(page).not_to have_text("England")
    end

    it "shows full hierarchy when max_levels is nil" do
      render_inline(described_class.new(neighbourhood: ward, max_levels: nil))

      expect(page).to have_text("England")
      expect(page).to have_text("Hackney Central")
    end
  end

  describe "with compact option" do
    it "uses smaller badges when compact is true" do
      render_inline(described_class.new(neighbourhood: district, compact: true))

      expect(page).to have_css(".px-1\\.5")
    end

    it "uses regular badges when compact is false" do
      render_inline(described_class.new(neighbourhood: district, compact: false))

      expect(page).to have_css(".px-2")
    end
  end

  describe "edge cases" do
    it "handles root neighbourhood" do
      render_inline(described_class.new(neighbourhood: country))

      expect(page).to have_text("England")
      expect(page).not_to have_text("/")
    end

    it "handles nil neighbourhood gracefully" do
      render_inline(described_class.new(neighbourhood: nil))

      expect(page.text.strip).to be_empty
    end
  end
end
