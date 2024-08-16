# frozen_string_literal: true

class PartnerFilterComponent < ViewComponent::Base
  def initialize(partners:, site:, selected_category:, selected_neighbourhood:)
    super
    @partners = partners
    @site = site
    @selected_category = selected_category.to_i
    @selected_neighbourhood = selected_neighbourhood.to_i
  end

  # Categories
  def categories
    @partners.map(&:categories).flatten.uniq.sort_by(&:name)
  end

  def category_selected?(id)
    @selected_category == id
  end

  def show_category_filter?
    categories.any?
  end

  # Neighbourhoods
  def neighbourhoods
    @partners.map(&:neighbourhoods).flatten.uniq.sort_by(&:name)
  end

  def neighbourhood_selected?(id)
    @selected_neighbourhood == id
  end
end
