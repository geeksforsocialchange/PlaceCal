# frozen_string_literal: true

class PartnerFilterComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(partners:, site:, selected_category:, selected_neighbourhood:)
    super()
    @partners = partners
    @site = site
    @selected_category = selected_category.to_i
    @selected_neighbourhood = selected_neighbourhood.to_i
    @query = PartnersQuery.new(site: @site)
  end

  def categories
    @categories ||= @query.categories_with_counts
  end

  def category_selected?(id)
    @selected_category == id
  end

  def show_category_filter?
    categories.any?
  end

  def neighbourhoods
    @neighbourhoods ||= @query.neighbourhoods_with_counts
  end

  def neighbourhood_selected?(id)
    @selected_neighbourhood == id
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive?
  end
end
