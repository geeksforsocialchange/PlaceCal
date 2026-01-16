# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::NeighbourhoodCardComponent, type: :component do
  # Set levels explicitly as they are stored in the database
  let(:country) { create(:neighbourhood, name: "England", unit: "country", level: 5) }
  let(:region) { create(:neighbourhood, name: "Yorkshire", unit: "region", level: 4, parent: country) }
  let(:county) { create(:neighbourhood, name: "West Yorkshire", unit: "county", level: 3, parent: region) }
  let(:district) { create(:neighbourhood, name: "Leeds", unit: "district", level: 2, parent: county) }
  let(:ward) { create(:neighbourhood, name: "Headingley", unit: "ward", level: 1, parent: district) }

  describe "basic rendering" do
    it "renders the neighbourhood card" do
      render_inline(described_class.new(neighbourhood: ward))
      expect(page).to have_css(".card")
    end

    it "displays the neighbourhood name" do
      render_inline(described_class.new(neighbourhood: ward))
      expect(page).to have_text("Headingley")
    end

    it "displays the neighbourhood unit type" do
      render_inline(described_class.new(neighbourhood: ward))
      expect(page).to have_text("Ward")
    end

    it "renders a link to the neighbourhood page" do
      render_inline(described_class.new(neighbourhood: ward))
      # In component tests without controller context, paths may not include /admin prefix
      expect(page).to have_css("a[href*='/neighbourhoods/']")
    end

    it "displays the level badge" do
      render_inline(described_class.new(neighbourhood: ward))
      # Level 1 ward shows "L1" in the badge
      expect(page).to have_text("L1")
    end
  end

  describe "hierarchy display" do
    it "displays ancestor neighbourhoods" do
      render_inline(described_class.new(neighbourhood: ward))
      expect(page).to have_text("England")
      expect(page).to have_text("Yorkshire")
      expect(page).to have_text("West Yorkshire")
      expect(page).to have_text("Leeds")
    end

    it "renders links for ancestors" do
      render_inline(described_class.new(neighbourhood: ward))
      # Should have multiple links to neighbourhood pages (5 total: ward + 4 ancestors)
      expect(page).to have_css("a[href*='/neighbourhoods/']", minimum: 5)
    end

    it "shows ancestors in order from country to district" do
      render_inline(described_class.new(neighbourhood: ward))
      # England should appear before Leeds in the hierarchy
      html = page.native.inner_html
      expect(html.index("England")).to be < html.index("Leeds")
    end
  end

  describe "with show_header option" do
    it "shows header when show_header is true" do
      render_inline(described_class.new(neighbourhood: ward, show_header: true))
      expect(page).to have_css("h3")
      expect(page).to have_text("Neighbourhood")
    end

    it "hides header when show_header is false" do
      render_inline(described_class.new(neighbourhood: ward, show_header: false))
      expect(page).not_to have_css("h3")
    end
  end

  describe "with show_remove option" do
    let(:partner) { create(:partner) }
    let(:service_area) { partner.service_areas.build(neighbourhood: ward) }
    let(:template) { ActionView::Base.empty }
    let(:form) do
      ActionView::Helpers::FormBuilder.new(:service_area, service_area, template, {})
    end

    it "shows remove button when show_remove is true and form is provided" do
      render_inline(described_class.new(neighbourhood: ward, show_remove: true, form: form))
      # The remove button is rendered with btn-ghost class
      expect(page).to have_css(".btn-ghost.btn-square")
    end

    it "hides remove button when show_remove is false" do
      render_inline(described_class.new(neighbourhood: ward, show_remove: false, form: form))
      expect(page).not_to have_css(".btn-ghost.btn-square")
    end
  end

  describe "root neighbourhood" do
    it "handles neighbourhood with no ancestors" do
      render_inline(described_class.new(neighbourhood: country))
      expect(page).to have_text("England")
      # Should have a link to the neighbourhood
      expect(page).to have_css("a[href*='/neighbourhoods/']")
    end
  end
end
