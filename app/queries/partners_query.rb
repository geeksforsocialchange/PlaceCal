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

  # Filter-dropdown facet counts. Delegated to PartnerFacets so this object
  # stays focused on selecting partners.
  delegate :neighbourhoods_with_counts, :neighbourhood_tree,
           :partnerships_with_counts, :categories_with_counts, to: :facets

  # Whether the given partner appears on this site — same rules as the
  # partner listing (address or service area in the site's neighbourhoods,
  # matching tag on tagged sites).
  #
  # @param partner [Partner]
  # @return [Boolean]
  def include?(partner)
    base_scope.exists?(partner.id)
  end

  private

  # @return [PartnerFacets] facet-count collaborator, defaulting to this site's
  #   partner scope
  def facets
    @facets ||= PartnerFacets.new(default_scope: base_scope)
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

  # A site scopes its partners by its neighbourhoods, by its tags, or by both
  # (tag AND neighbourhood). A tagged site with no neighbourhoods is tag-only:
  # partnership sites such as The Trans Dimension span cities and pick their
  # partners by Partnership tag alone (#3368 D7, D24). A site with neither
  # has no partners.
  def build_base_scope
    return Partner.visible if @site.nil?
    return Partner.none if !site_has_neighbourhoods? && site_tag_ids.empty?

    scope = Partner.visible
    scope = scope.joins(:tags).where(tags: { id: site_tag_ids }) if site_tag_ids.any?
    scope = scope.left_joins(:address, :service_areas).where(in_site_neighbourhoods_sql) if site_has_neighbourhoods?
    scope.distinct
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
    node = Neighbourhood.find_by(id: neighbourhood_id)
    return partners.none unless node

    partners
      .left_joins(:address, :service_areas)
      .where(in_neighbourhood_subtree_sql(Neighbourhood.subtree_of(node)))
      .distinct
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
    in_neighbourhood_subtree_sql(@site.owned_neighbourhoods_subtree)
  end

  # Match a partner whose address or service area sits anywhere in +subtree+,
  # embedding it as a subquery so the subtree stays in the database rather than
  # arriving as a literal id list. +subtree+ is a Neighbourhood relation built
  # from trusted records (site or dropdown selection), never user input.
  #
  # @param subtree [ActiveRecord::Relation<Neighbourhood>]
  # @return [String] a WHERE fragment
  def in_neighbourhood_subtree_sql(subtree)
    ids = subtree.select(:id).to_sql
    "addresses.neighbourhood_id IN (#{ids}) OR service_areas.neighbourhood_id IN (#{ids})"
  end

  def site_has_neighbourhoods?
    return @site_has_neighbourhoods if defined?(@site_has_neighbourhoods)

    @site_has_neighbourhoods = @site.neighbourhoods.exists?
  end

  def site_tag_ids
    @site_tag_ids ||= @site.tags.pluck(:id)
  end
end
