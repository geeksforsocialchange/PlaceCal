# frozen_string_literal: true

class PartnerFilterComponent < ViewComponent::Base
  include Turbo::FramesHelper

  attr_reader :selected_category, :selected_neighbourhood

  def initialize(site:, selected_category:, selected_neighbourhood:)
    super()
    @site = site
    @selected_category = selected_category.to_i
    @selected_neighbourhood = selected_neighbourhood.to_i
    @query = PartnersQuery.new(site: @site)
  end

  def categories
    @categories ||= @query.categories_with_counts
  end

  def category_items
    categories.map do |c|
      { id: c[:category].id, name: c[:category].name, count: c[:count] }
    end
  end

  def category_selected?(id)
    @selected_category == id
  end

  def show_category_filter?
    categories.length > 1
  end

  def neighbourhoods
    @neighbourhoods ||= @query.neighbourhoods_with_counts
  end

  def neighbourhood_items
    neighbourhoods.map do |n|
      { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] }
    end
  end

  def neighbourhood_selected?(id)
    @selected_neighbourhood == id
  end

  def show_neighbourhood_filter?
    neighbourhoods.length > 1
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive?
  end
end
