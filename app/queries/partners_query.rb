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
  # Area-breadcrumb label per partner id for the directory cards
  # (e.g. "Manchester › Hulme › Moss Side"). Each partner's neighbourhood is
  # its address neighbourhood, falling back to its first service area. Ancestors
  # are batch-loaded so the partner index doesn't fire an ancestors query per
  # card (the partner_card used to call hierarchy_path itself — an N+1).
  #
  # @param partners [Enumerable<Partner>] partners eager-loaded with their
  #   address neighbourhood and service areas
  # @return [Hash{Integer=>String,nil}] partner id => breadcrumb label (or nil)
  def self.area_labels(partners)
    partners = partners.to_a
    return {} if partners.empty?

    # Resolving service_area_neighbourhoods.first below would query per partner;
    # preload the through-association once.
    ActiveRecord::Associations::Preloader.new(records: partners, associations: :service_area_neighbourhoods).call

    neighbourhoods = partners.to_h do |partner|
      hood = partner.address&.neighbourhood
      hood ||= partner.service_area_neighbourhoods.first if partner.has_service_areas?
      [partner.id, hood]
    end

    ancestors = Neighbourhood.where(id: neighbourhoods.values.compact.flat_map(&:ancestor_ids).uniq).index_by(&:id)

    neighbourhoods.transform_values do |hood|
      next unless hood

      path = hood.ancestor_ids.filter_map { |id| ancestors[id] } + [hood]
      path.last(3).map(&:shortname).join(' › ')
    end
  end

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
    pairs = neighbourhood_partner_pairs(scope: scope)
    return [] if pairs.empty?

    direct_ids = pairs.map { |r| r['neighbourhood_id'] }.uniq
    neighbourhoods = Neighbourhood.where(id: direct_ids).order(:name).to_a

    # Roll each partner up to its neighbourhood and all listed ancestors, so an
    # area-level neighbourhood's count matches what filtering by it returns (its
    # whole subtree) and the dropdown stays consistent with the results.
    counts = rollup_partner_counts(pairs, neighbourhoods.index_by(&:id))

    neighbourhoods.map { |n| { neighbourhood: n, count: counts[n.id] } }
  end

  # Returns the full geographic hierarchy of neighbourhoods that have partners,
  # as a nested tree for the directory's cascading neighbourhood filter.
  #
  # Every neighbourhood a partner is assigned to is included along with all of
  # its ancestors, so the cascade can be drilled region > county > district >
  # ward. Each node's count is the number of distinct partners in its subtree,
  # matching what filtering by that node returns. The country level is dropped
  # (it filters to everything, same as no filter) and its children become roots.
  #
  # @param selected_id [Integer, String, nil] keep this neighbourhood in the
  #   tree even when the current scope leaves it with no partners, so the picker
  #   still reflects the active selection
  # @return [Array<Hash>] nested nodes of
  #   { id:, name:, unit:, count:, children: [...] }
  def neighbourhood_tree(scope: nil, selected_id: nil)
    pairs = neighbourhood_partner_pairs(scope: scope)
    direct = Neighbourhood.where(id: pairs.map { |r| r['neighbourhood_id'] }.uniq).to_a

    selected = Neighbourhood.find_by(id: selected_id) if selected_id.present?
    direct << selected if selected && direct.none? { |n| n.id == selected.id }

    return [] if direct.empty?

    ancestor_ids = direct.flat_map(&:ancestor_ids).uniq
    nodes = Neighbourhood.where(id: (direct.map(&:id) + ancestor_ids).uniq).to_a
    by_id = nodes.index_by(&:id)

    counts = rollup_partner_counts(pairs, by_id)
    build_neighbourhood_tree(nodes, by_id, counts)
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
  # Neighbourhood roll-up helpers
  # ===================

  # Distinct (neighbourhood_id, partner_id) pairs for partners in the scope,
  # via either their address or a service area. Shared by the dropdown count
  # and the cascade tree so both reflect the same set of partners.
  #
  # @return [Array<Hash>] rows with 'neighbourhood_id' and 'partner_id'
  def neighbourhood_partner_pairs(scope: nil)
    partner_ids = (scope || base_scope).reorder(nil).select(:id)

    ActiveRecord::Base.connection.select_all(<<~SQL).to_a # rubocop:disable Rails/SquishedSQLHeredocs
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
  end

  # Credit each partner to its neighbourhood and every ancestor present in
  # +by_id+, so an area-level node's count matches its whole subtree.
  #
  # @param pairs [Array<Hash>] neighbourhood/partner rows
  # @param by_id [Hash{Integer => Neighbourhood}] nodes to credit
  # @return [Hash{Integer => Integer}] neighbourhood id => distinct partner count
  def rollup_partner_counts(pairs, by_id)
    partner_sets = Hash.new { |hash, key| hash[key] = Set.new }
    pairs.each do |row|
      node = by_id[row['neighbourhood_id']]
      next unless node

      [node.id, *node.ancestor_ids].each do |id|
        partner_sets[id] << row['partner_id'] if by_id.key?(id)
      end
    end
    partner_sets.transform_values(&:size)
  end

  # Assemble +nodes+ into a nested tree, dropping the country level and
  # re-rooting its children. Children are sorted by name at every level.
  #
  # @return [Array<Hash>] root nodes of { id:, name:, unit:, count:, children: }
  def build_neighbourhood_tree(nodes, by_id, counts)
    children_of = Hash.new { |hash, key| hash[key] = [] }
    roots = []

    nodes.each do |node|
      next if country?(node)

      parent = by_id[node.parent_id]
      if parent.nil? || country?(parent)
        roots << node
      else
        children_of[node.parent_id] << node
      end
    end

    build = lambda do |node|
      {
        id: node.id,
        name: node.shortname,
        unit: node.unit.to_s,
        count: counts[node.id] || 0,
        children: children_of[node.id].sort_by { |c| c.shortname.downcase }.map(&build)
      }
    end

    roots.sort_by { |n| n.shortname.downcase }.map(&build)
  end

  # @return [Boolean] whether the node is country-level (the unit attribute is
  #   the canonical level marker; the numeric `level` column is often unset)
  def country?(node)
    node.unit.to_s == 'country'
  end

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
    return Partner.visible if @site.nil?
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
