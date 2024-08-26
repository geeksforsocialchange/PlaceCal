# frozen_string_literal: true

require 'test_helper'

class PartnerFilterComponentTest < ViewComponent::TestCase
  setup do
    @site = create(:site)
  end

  def test_component_renders_something_useful
    @partners = create_list(:partner, 5)

    render_inline(PartnerFilterComponent.new(partners: @partners, site: @site, selected_category: nil, selected_neighbourhood: nil))

    assert_no_selector 'span.filters__link', text: 'Category'
    assert_selector 'span.filters__link', text: 'Neighbourhood'
  end

  def test_show_category_dropdown_if_no_category
    @partners = create_list(:partner, 5) do |partner|
      partner.categories << create(:category)
    end

    render_inline(PartnerFilterComponent.new(partners: @partners, site: @site, selected_category: nil, selected_neighbourhood: nil))

    assert_selector 'span.filters__link', text: 'Category'
  end
end
