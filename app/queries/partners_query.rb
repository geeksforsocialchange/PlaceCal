# frozen_string_literal: true

# Query object for filtering partners by site, neighbourhood, and tags
#
# @example Basic usage
#   PartnersQuery.new(site: current_site).call
#
# @example With filters
#   PartnersQuery.new(site: current_site).call(
#     neighbourhood_id: 123,
#     tag_id: 456
#   )
#
class PartnersQuery
  def initialize(site:)
    @site = site
  end

  # Main entry point - returns partners filtered and sorted
  #
  # @param neighbourhood_id [Integer] filter by neighbourhood (address or service area)
  # @param tag_id [Integer] filter by tag/category
  # @param tag_slug [String] filter by tag slug (e.g. 'computers', 'wifi')
  # @return [ActiveRecord::Relation<Partner>]
  def call(neighbourhood_id: nil, tag_id: nil, tag_slug: nil)
    partners = base_scope
    partners = filter_by_neighbourhood(partners, neighbourhood_id) if neighbourhood_id.present?
    partners = filter_by_tag(partners, tag_id) if tag_id.present?
    partners = filter_by_tag_slug(partners, tag_slug) if tag_slug.present?
    partners.includes(:address, :service_areas).order(:name)
  end

  # Returns neighbourhoods that have partners, with counts
  # Used for filter dropdowns
  #
  # @return [Array<Hash>] array of { neighbourhood: Neighbourhood, count: Integer }
  def neighbourhoods_with_counts
    Neighbourhood
      .joins(addresses: :partners)
      .where(partners: { id: base_scope.select(:id) })
      .group(:id, :name)
      .order(:name)
      .select('neighbourhoods.*, COUNT(DISTINCT partners.id) as partner_count')
      .map { |n| { neighbourhood: n, count: n.partner_count } }
  end

  # Returns categories/tags that have partners, with counts
  # Used for filter dropdowns
  #
  # @return [Array<Hash>] array of { category: Tag, count: Integer }
  def categories_with_counts
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: base_scope.select(:id) }, type: 'Category')
      .group(:id, :name)
      .order(:name)
      .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
      .map { |tag| { category: tag, count: tag.partner_count } }
  end

  private

  # ===================
  # Base Scope
  # ===================

  # Partners belong to a site via:
  # 1. Their address being in a site's neighbourhood, OR
  # 2. Their service areas overlapping with site's neighbourhoods
  def base_scope
    @base_scope ||= build_base_scope
  end

  def build_base_scope
    return Partner.none if site_neighbourhood_ids.empty?

    scope = Partner.visible
    scope = scope.joins(:tags).where(tags: { id: site_tag_ids }) if site_tag_ids.any?
    scope
      .left_joins(:address, :service_areas)
      .where(in_site_neighbourhoods_sql)
      .distinct
  end

  # ===================
  # Filtering
  # ===================

  # Filter by neighbourhood (partner's address OR service area)
  def filter_by_neighbourhood(partners, neighbourhood_id)
    partners
      .left_joins(:address, :service_areas)
      .where(
        'addresses.neighbourhood_id = :id OR service_areas.neighbourhood_id = :id',
        id: neighbourhood_id
      )
  end

  def filter_by_tag(partners, tag_id)
    partners.joins(:tags).where(tags: { id: tag_id })
  end

  def filter_by_tag_slug(partners, tag_slug)
    partners.joins(:tags).where(tags: { slug: tag_slug })
  end

  # ===================
  # Site Scope Helpers
  # ===================

  def in_site_neighbourhoods_sql
    [
      'addresses.neighbourhood_id IN (:ids) OR service_areas.neighbourhood_id IN (:ids)',
      { ids: site_neighbourhood_ids }
    ]
  end

  def site_neighbourhood_ids
    @site_neighbourhood_ids ||= @site.owned_neighbourhood_ids
  end

  def site_tag_ids
    @site_tag_ids ||= @site.tags.pluck(:id)
  end
end
