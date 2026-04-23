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
# @example With pagination
#   query = PartnersQuery.new(site: current_site)
#   partners = query.call(page: 2)
#   query.total_pages    # => 5
#   query.page_letter_ranges # => [{ page: 1, first_label: "A", last_label: "C" }, ...]
#
class PartnersQuery
  PER_PAGE = 50

  def initialize(site:)
    @site = site
  end

  attr_reader :total_pages, :total_count

  # Main entry point - returns partners filtered and sorted
  #
  # @param neighbourhood_id [Integer] filter by neighbourhood (address or service area)
  # @param tag_id [Integer] filter by tag/category
  # @param tag_slug [String] filter by tag slug (e.g. 'computers', 'wifi')
  # @param page [Integer] page number (1-indexed), nil for no pagination
  # @param per_page [Integer] number of results per page
  # @return [ActiveRecord::Relation<Partner>]
  def call(neighbourhood_id: nil, tag_id: nil, tag_slug: nil, page: nil, per_page: PER_PAGE)
    partners = base_scope
    partners = filter_by_neighbourhood(partners, neighbourhood_id) if neighbourhood_id.present?
    partners = filter_by_tag(partners, tag_id) if tag_id.present?
    partners = filter_by_tag_slug(partners, tag_slug) if tag_slug.present?
    @filtered_scope = partners.includes(:address, :service_areas).order(:name)

    if page
      @total_count = @filtered_scope.count
      @total_pages = [(@total_count.to_f / per_page).ceil, 1].max
      page = page.clamp(1, @total_pages)
      @filtered_scope.offset((page - 1) * per_page).limit(per_page)
    else
      @total_count = nil
      @total_pages = 1
      @filtered_scope
    end
  end

  # Returns letter-range labels for each page of the filtered results
  # Uses two-char prefixes when a letter spans a page boundary
  #
  # @param per_page [Integer] results per page
  # @return [Array<Hash>] array of { page:, first_label:, last_label: }
  def page_letter_ranges(per_page: PER_PAGE)
    names = filtered_scope_names
    return [] if names.empty?

    ranges = names.each_slice(per_page).with_index.map do |slice, i|
      { page: i + 1, first_label: slice.first, last_label: slice.last }
    end
    compute_labels(ranges)
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

  # ===================
  # Pagination Helpers
  # ===================

  def filtered_scope_names
    @filtered_scope_names ||= (@filtered_scope || base_scope.order(:name)).pluck(:name)
  end

  # Compute display labels for page ranges. Uses single letter when unambiguous,
  # two-char prefix when a letter spans a page boundary (e.g. "Ce" vs "Cl")
  def compute_labels(ranges)
    ranges.each_with_index do |r, i|
      prev_last = i.positive? ? ranges[i - 1][:last_label] : nil
      next_first = i < ranges.length - 1 ? ranges[i + 1][:first_label] : nil

      first_name = r[:first_label]
      last_name = r[:last_label]

      r[:first_label] = smart_label(first_name, prev_last, :start)
      r[:last_label] = smart_label(last_name, next_first, :end)
    end
    ranges
  end

  # Generate a label for a page boundary name.
  # Uses single letter if unambiguous, two-char prefix if the same letter
  # appears on both sides of the boundary.
  def smart_label(name, adjacent_name, _position)
    letter = name[0].upcase
    return letter unless adjacent_name

    adjacent_letter = adjacent_name[0].upcase
    if letter == adjacent_letter
      # Same letter on both sides of boundary — use two-char prefix
      name[0..1].capitalize
    else
      letter
    end
  end
end
