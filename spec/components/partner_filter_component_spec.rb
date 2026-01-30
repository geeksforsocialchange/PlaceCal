# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerFilterComponent, type: :component do
  describe "with partners in multiple neighbourhoods" do
    let(:neighbourhood1) { create(:neighbourhood) }
    let(:neighbourhood2) { create(:neighbourhood) }
    let(:site) { create(:site, neighbourhoods: [neighbourhood1, neighbourhood2]) }
    let(:address1) { create(:address, neighbourhood: neighbourhood1) }
    let(:address2) { create(:address, neighbourhood: neighbourhood2) }
    let(:partners) do
      [
        create(:partner, address: address1),
        create(:partner, address: address2)
      ]
    end

    it "shows neighbourhood filter when multiple neighbourhoods exist" do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).to have_selector("button span.filters__link", text: "Neighbourhood")
    end

    it "does not show category filter when no partners have categories" do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).not_to have_selector("button span.filters__link", text: "Category")
    end
  end

  describe "with partners with categories" do
    let(:site_with_neighbourhood) { create(:ashdale_site) }
    let(:category1) { create(:category_tag) }
    let(:category2) { create(:category_tag) }
    let(:partners) do
      create_list(:partner, 3) do |partner|
        # Associate partner with site via service area
        partner.service_areas << create(:service_area, neighbourhood: site_with_neighbourhood.primary_neighbourhood)
      end
    end

    before do
      # Add different categories to make the filter appear (need > 1 category)
      partners.first.categories << category1
      partners.second.categories << category2
    end

    it "shows category filter dropdown when multiple categories exist" do
      render_inline(described_class.new(
                      partners: partners,
                      site: site_with_neighbourhood,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).to have_selector("button span.filters__link", text: "Category")
    end
  end

  describe "with selected filters" do
    let(:neighbourhood1) { create(:neighbourhood) }
    let(:neighbourhood2) { create(:neighbourhood) }
    let(:site) { create(:site, neighbourhoods: [neighbourhood1, neighbourhood2]) }
    let(:address1) { create(:address, neighbourhood: neighbourhood1) }
    let(:address2) { create(:address, neighbourhood: neighbourhood2) }
    let(:category) { create(:category_tag) }
    let(:partners) do
      [
        create(:partner, address: address1),
        create(:partner, address: address2)
      ]
    end

    it "renders with selected category" do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: category.slug,
                      selected_neighbourhood: nil
                    ))

      # Component should render without errors - neighbourhood filter shows when multiple neighbourhoods
      expect(page).to have_selector("button span.filters__link", text: "Neighbourhood")
    end

    it "renders with selected neighbourhood and shows selected name" do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: neighbourhood1.id
                    ))

      # When a neighbourhood is selected, it shows the neighbourhood name instead of "Neighbourhood"
      expect(page).to have_selector("button span.filters__link", text: neighbourhood1.name)
    end
  end
end
