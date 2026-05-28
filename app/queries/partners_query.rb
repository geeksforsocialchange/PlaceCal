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
  # @param partnership_id [Integer] filter by partnership (Site) tag
  # @param query [String] keyword search on name/summary
  # @return [ActiveRecord::Relation<Partner>]
  def call(neighbourhood_id: nil, tag_id: nil, tag_slug: nil, partnership_id: nil, query: nil, sort: 'name') # rubocop:disable Metrics/ParameterLists
    partners = base_scope
    partners = filter_by_neighbourhood(partners, neighbourhood_id) if neighbourhood_id.present?
    partners = filter_by_tag(partners, tag_id) if tag_id.present?
    partners = filter_by_tag_slug(partners, tag_slug) if tag_slug.present?
    partners = filter_by_partnership(partners, partnership_id) if partnership_id.present?
    partners = filter_by_query(partners, query) if query.present?
    partners.includes({ address: :neighbourhood }, { service_areas: :neighbourhood }, :categories).order(sort_clause(sort))
  end

  # Returns neighbourhoods that have partners, with counts
  # Used for filter dropdowns
  #
  # @return [Array<Hash>] array of { neighbourhood: Neighbourhood, count: Integer }
  def neighbourhoods_with_counts(scope: nil)
    partner_ids = (scope || base_scope).reorder(nil).select(:id)

    pairs = ActiveRecord::Base.connection.select_all(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
      SELECT neighbourhood_id, partner_id FROM (
        SELECT a.neighbourhood_id, p.id AS partner_id
        FROM partners p
        INNER JOIN addresses a ON a.id = p.address_id
        WHERE p.id IN (#{partner_ids.to_sql})
          AND a.neighbourhood_id IS NOT NULL
        UNION
        SELECT sa.neighbourhood_id, sa.partner_id
        FROM service_areas sa
        WHERE sa.partner_id IN (#{partner_ids.to_sql})
          AND sa.neighbourhood_id IS NOT NULL
      ) AS combined
    SQL

    counts = pairs.group_by { |r| r['neighbourhood_id'] }
                  .transform_values { |rows| rows.map { |r| r['partner_id'] }.uniq.length }

    return [] if counts.empty?

    Neighbourhood.where(id: counts.keys).order(:name).map do |n|
      { neighbourhood: n, count: counts[n.id] }
    end
  end

  # Returns partnerships that have partners, with counts
  # Used for filter dropdowns on the directory site
  #
  # @return [Array<Hash>] array of { partnership: Partnership, count: Integer }
  def partnerships_with_counts(scope: nil)
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: (scope || base_scope).reorder(nil).select(:id) }, type: 'Partnership')
      .group(:id, :name)
      .order(:name)
      .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
      .map { |tag| { partnership: tag, count: tag.partner_count } }
  end

  # Returns categories/tags that have partners, with counts
  # Used for filter dropdowns
  #
  # @return [Array<Hash>] array of { category: Tag, count: Integer }
  def categories_with_counts(scope: nil)
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: (scope || base_scope).reorder(nil).select(:id) }, type: 'Category')
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
    return Partner.visible if @site&.directory_site?
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
    partners.where(id: PartnerTag.where(tag_id: tag_id).select(:partner_id))
  end

  def filter_by_tag_slug(partners, tag_slug)
    partners.where(id: PartnerTag.joins(:tag).where(tags: { slug: tag_slug }).select(:partner_id))
  end

  def filter_by_partnership(partners, partnership_id)
    partners.where(id: PartnerTag.where(tag_id: partnership_id).select(:partner_id))
  end

  def filter_by_query(partners, query)
    partners.where('partners.name ILIKE :q OR partners.summary ILIKE :q', q: "%#{query}%")
  end

  def sort_clause(sort)
    case sort
    when 'recent' then { updated_at: :desc }
    else { name: :asc }
    end
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
