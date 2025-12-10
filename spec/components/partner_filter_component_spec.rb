# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerFilterComponent, type: :component do
  let(:site) { create(:site) }

  describe 'with partners without categories' do
    let(:partners) { create_list(:partner, 3) }

    it 'shows neighbourhood filter' do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).to have_selector('span.filters__link', text: 'Neighbourhood')
    end

    it 'does not show category filter when no partners have categories' do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).not_to have_selector('span.filters__link', text: 'Category')
    end
  end

  describe 'with partners with categories' do
    let(:partners) do
      create_list(:partner, 3) do |partner|
        partner.categories << create(:category_tag)
      end
    end

    it 'shows category filter dropdown' do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: nil
                    ))

      expect(page).to have_selector('span.filters__link', text: 'Category')
    end
  end

  describe 'with selected filters' do
    let(:partners) { create_list(:partner, 2) }
    let(:category) { create(:category_tag) }
    let(:neighbourhood) { create(:riverside_ward) }

    it 'renders with selected category' do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: category.slug,
                      selected_neighbourhood: nil
                    ))

      # Component should render without errors
      expect(page).to have_selector('span.filters__link', text: 'Neighbourhood')
    end

    it 'renders with selected neighbourhood' do
      render_inline(described_class.new(
                      partners: partners,
                      site: site,
                      selected_category: nil,
                      selected_neighbourhood: neighbourhood.name
                    ))

      # Component should render without errors
      expect(page).to have_selector('span.filters__link', text: 'Neighbourhood')
    end
  end
end
