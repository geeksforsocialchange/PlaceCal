# frozen_string_literal: true

# Filter-dropdown facet counts for a site's (or the directory's) partners:
# neighbourhoods, the cascading neighbourhood tree, partnerships and
# categories, each with a distinct-partner count. Extracted from PartnersQuery
# so that object stays focused on selecting partners (app/queries, single
# responsibility); PartnersQuery delegates its facet methods here.
#
# Every method takes an optional +scope+ (a partners relation) and falls back
# to the default scope the facets were built with, so callers can cross-filter
# the counts on the other active filters.
class PartnerFacets
  # @param default_scope [ActiveRecord::Relation<Partner>] the site's partners,
  #   used when a method is called without an explicit scope
  def initialize(default_scope:)
    @default_scope = default_scope
  end

  # Neighbourhoods that have partners, with counts. Used for filter dropdowns.
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

  # The full geographic hierarchy of neighbourhoods that have partners, as a
  # nested tree for the directory's cascading neighbourhood filter.
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
  # @return [Array<Hash>] nested nodes of { id:, name:, unit:, count:, children: }
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

  # Partnerships that have partners, with counts. Directory filter dropdown.
  #
  # @return [Array<Hash>] array of { partnership: Partnership, count: Integer }
  def partnerships_with_counts(scope: nil)
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: (scope || @default_scope).reorder(nil).select(:id) }, type: 'Partnership')
      .group(:id, :name)
      .order(:name)
      .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
      .map { |tag| { partnership: tag, count: tag.partner_count } }
  end

  # Categories that have partners, with counts. Used for filter dropdowns.
  #
  # @return [Array<Hash>] array of { category: Tag, count: Integer }
  def categories_with_counts(scope: nil)
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: (scope || @default_scope).reorder(nil).select(:id) }, type: 'Category')
      .group(:id, :name)
      .order(:name)
      .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
      .map { |tag| { category: tag, count: tag.partner_count } }
  end

  private

  # Distinct (neighbourhood_id, partner_id) pairs for partners in the scope,
  # via either their address or a service area. Shared by the dropdown count
  # and the cascade tree so both reflect the same set of partners.
  #
  # @return [Array<Hash>] rows with 'neighbourhood_id' and 'partner_id'
  def neighbourhood_partner_pairs(scope: nil)
    partner_ids = (scope || @default_scope).reorder(nil).select(:id)

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
end
