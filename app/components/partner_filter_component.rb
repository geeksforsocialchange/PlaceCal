# frozen_string_literal: true

class PartnerFilterComponent < ViewComponent::Base
  include Turbo::FramesHelper

  def initialize(partners:, site:, selected_category:, selected_neighbourhood:)
    super()
    @partners = partners
    @site = site
    @selected_category = selected_category.to_i
    @selected_neighbourhood = selected_neighbourhood.to_i
  end

  # Categories - show all from site's partners with counts (optimized SQL query)
  def categories
    @categories ||= begin
      partner_ids = Partner.for_site(@site).select(:id)
      Tag.joins(:partner_tags)
         .where(partner_tags: { partner_id: partner_ids }, type: 'Category')
         .group('tags.id', 'tags.name')
         .order('tags.name')
         .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
         .map { |tag| { category: tag, count: tag.partner_count } }
    end
  end

  def category_selected?(id)
    @selected_category == id
  end

  def show_category_filter?
    categories.any?
  end

  # Neighbourhoods - show all from site's partners with counts
  # Uses address-based neighbourhoods for partner counts
  def neighbourhoods
    @neighbourhoods ||= begin
      partner_ids = Partner.for_site(@site).pluck(:id)
      Neighbourhood.joins(addresses: :partners)
                   .where(partners: { id: partner_ids })
                   .group('neighbourhoods.id', 'neighbourhoods.name')
                   .order('neighbourhoods.name')
                   .select('neighbourhoods.*, COUNT(DISTINCT partners.id) as partner_count')
                   .map { |n| { neighbourhood: n, count: n.partner_count } }
    end
  end

  def neighbourhood_selected?(id)
    @selected_neighbourhood == id
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive?
  end
end
