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

    return [] if pairs.empty?

    direct_ids = pairs.map { |r| r['neighbourhood_id'] }.uniq
    neighbourhoods = Neighbourhood.where(id: direct_ids).order(:name).to_a

    # Roll each partner up to its neighbourhood and all listed ancestors, so an
    # area-level neighbourhood's count matches what filtering by it returns (its
    # whole subtree) and the dropdown stays consistent with the results.
    listed = neighbourhoods.index_by(&:id)
    partner_sets = Hash.new { |hash, key| hash[key] = Set.new }
    pairs.each do |row|
      node = listed[row['neighbourhood_id']]
      next unless node

      credited = [node.id] + node.ancestor_ids.select { |id| listed.key?(id) }
      credited.each { |id| partner_sets[id] << row['partner_id'] }
    end

    neighbourhoods.map { |n| { neighbourhood: n, count: partner_sets[n.id].size } }
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

  # Filter by neighbourhood (partner's address OR service area).
  #
  # Matches the neighbourhood and all of its descendants, so an area-level
  # neighbourhood (e.g. "Manchester" the district) includes partners living
  # in its wards, not just those assigned to the area node itself.
  def filter_by_neighbourhood(partners, neighbourhood_id)
    ids = neighbourhood_subtree_ids(neighbourhood_id)
    return partners.none if ids.empty?

    partners
      .left_joins(:address, :service_areas)
      .where(
        'addresses.neighbourhood_id IN (:ids) OR service_areas.neighbourhood_id IN (:ids)',
        ids: ids
      )
      .distinct
  end

  # @return [Array<Integer>] the neighbourhood id plus all descendant ids, or
  #   [] when the id is blank/unknown — so an invalid filter matches nothing
  #   rather than raising on a non-integer value passed to an integer column.
  def neighbourhood_subtree_ids(neighbourhood_id)
    Neighbourhood.find_by(id: neighbourhood_id)&.subtree_ids || []
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
