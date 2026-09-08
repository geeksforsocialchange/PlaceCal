# frozen_string_literal: true

# Filter-dropdown facet counts for a site's (or the directory's) partners:
# neighbourhoods, the cascading neighbourhood tree, partnerships and
# categories, each with a distinct-partner count. Every method takes an
# optional +scope+ and falls back to the default the facets were built with,
# so callers can cross-filter the counts on the other active filters.
class PartnerFacets
  def initialize(default_scope:)
    @default_scope = default_scope
  end

  # @return [Array<Hash>] { neighbourhood:, count: }
  def neighbourhoods_with_counts(scope: nil)
    pairs = neighbourhood_partner_pairs(scope: scope)
    return [] if pairs.empty?

    direct_ids = pairs.map { |r| r['neighbourhood_id'] }.uniq
    neighbourhoods = Neighbourhood.where(id: direct_ids).order(:name).to_a
    counts = rollup_partner_counts(pairs, neighbourhoods.index_by(&:id))

    neighbourhoods.map { |n| { neighbourhood: n, count: counts[n.id] } }
  end

  # The nested neighbourhood hierarchy for the directory's cascading filter:
  # every assigned neighbourhood plus its ancestors, each node counting the
  # distinct partners in its subtree. The country level is dropped and its
  # children become roots.
  #
  # @param selected_id keeps that neighbourhood in the tree even when the scope
  #   leaves it empty, so the picker still reflects the active selection
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

  # @return [Array<Hash>] { partnership:, count: }
  def partnerships_with_counts(scope: nil)
    tags_with_counts('Partnership', scope).map { |tag| { partnership: tag, count: tag.partner_count } }
  end

  # @return [Array<Hash>] { category:, count: }
  def categories_with_counts(scope: nil)
    tags_with_counts('Category', scope).map { |tag| { category: tag, count: tag.partner_count } }
  end

  private

  def tags_with_counts(type, scope)
    Tag
      .joins(:partner_tags)
      .where(partner_tags: { partner_id: (scope || @default_scope).reorder(nil).select(:id) }, type: type)
      .group(:id, :name)
      .order(:name)
      .select('tags.*, COUNT(partner_tags.partner_id) as partner_count')
  end

  # Distinct (neighbourhood_id, partner_id) pairs for partners in the scope, via
  # address or service area. Shared by the dropdown and the tree so both reflect
  # the same partners.
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
  # +by_id+, so an area-level node's count spans its whole subtree.
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

  # Nest +nodes+ into a tree, dropping the country level and re-rooting its
  # children, sorted by name at every level.
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

  # unit is the canonical level marker; the numeric `level` column is often unset.
  def country?(node)
    node.unit.to_s == 'country'
  end
end
