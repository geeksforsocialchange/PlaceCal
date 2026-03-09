# frozen_string_literal: true

# Query object for filtering and sorting events
#
# @example Basic usage
#   EventsQuery.new(site: current_site).call(period: 'week')
#
# @example With filters
#   EventsQuery.new(site: current_site).call(
#     period: 'week',
#     neighbourhood_id: 123,
#     sort: 'time'
#   )
#
# @example For an organiser's events (used on organiser show page)
#   EventsQuery.new(site: nil).call(
#     period: 'week',
#     organiser_or_place: organiser
#   )
#
class EventsQuery
  FUTURE_LIMIT = 50
  UPCOMING_LIMIT = 10
  WEEKLY_DENSITY_THRESHOLD = 10

  def initialize(site:, day: Time.zone.today)
    @site = site
    @day = day
    @truncated = false
  end

  attr_reader :truncated

  # Main entry point - returns events filtered, sorted, and grouped by day
  #
  # @param period [String] 'day', 'week', or 'future'
  # @param sort [String] 'time' (default) or 'summary'
  # @param repeating [String] 'on' (default), 'off', or 'last'
  # @param organiser [Partner] filter to events by this organiser
  # @param place [Partner] filter to events at this place
  # @param organiser_or_place [Partner] filter to events by OR at this organiser
  # @param neighbourhood_id [Integer] filter to events in this neighbourhood
  # @param limit [Integer] max number of events to return
  #
  # @return [Hash] events grouped by date { Date => [Event, ...] }
  # rubocop:disable Metrics/ParameterLists
  def call(period:, sort: 'time', repeating: 'on', organiser: nil, place: nil,
           organiser_or_place: nil, neighbourhood_id: nil, limit: nil)
    # rubocop:enable Metrics/ParameterLists
    events = build_filtered_scope(
      organiser: organiser,
      place: place,
      organiser_or_place: organiser_or_place,
      neighbourhood_id: neighbourhood_id,
      repeating: repeating
    )
    events = apply_period(events, period)
    events = events.limit(limit) if limit
    group_and_sort(events, sort)
  end

  # Returns the base scope as a flat relation for further chaining
  #
  # @return [ActiveRecord::Relation<Event>]
  def scope
    base_scope
  end

  # Returns events as a flat relation for iCal feeds (no grouping)
  def for_ical
    base_scope.ical_feed
  end

  # Efficient count for a period (no grouping or sorting)
  #
  # @param period [String] 'day', 'week', or 'future'
  # @return [Integer]
  def count_for_period(period)
    apply_period(base_scope, period).count
  end

  # Count methods for determining default period
  def future_count
    base_scope.future(@day).count
  end

  def next_7_days_count
    base_scope.find_next_7_days(@day).count
  end

  def monthly_count
    base_scope.for_month(@day).count
  end

  def show_monthly?
    monthly_count <= FUTURE_LIMIT
  end

  def next_event_after(day)
    base_scope.future(day).first
  end

  # Returns neighbourhoods that have events, with counts for the given period
  # Used for filter dropdowns
  #
  # Shows all descendant neighbourhoods of the site's configured neighbourhoods,
  # at every level. Each neighbourhood's count includes events in its subtree.
  #
  # @param period [String] 'day', 'week', or 'future'
  # @return [Array<Hash>] array of { neighbourhood: Neighbourhood, count: Integer }
  def neighbourhoods_with_counts(period: 'future')
    return [] unless @site

    all_descendants = @site.neighbourhoods.flat_map { |n| n.descendants.to_a }
    return [] if all_descendants.empty?

    events = apply_period(base_scope, period)

    # Count events per leaf neighbourhood (single query)
    raw_counts = events
                 .left_joins(:address, organiser: :address)
                 .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IS NOT NULL')
                 .group('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id)')
                 .distinct
                 .count

    # Build parent→children map from ancestry data already in memory,
    # then compute subtree counts without extra DB queries
    subtree_counts = subtree_counts_from_ancestry(all_descendants, raw_counts)

    all_descendants
      .select { |n| (subtree_counts[n.id] || 0).positive? }
      .sort_by(&:name)
      .map { |n| { neighbourhood: n, count: subtree_counts[n.id] } }
  end

  private

  # ===================
  # Base Scope
  # ===================

  def base_scope
    @base_scope ||= @site ? events_for_site.includes(:place, :organiser) : Event.includes(:place, :organiser)
  end

  # Inline of Event.for_site - finds events belonging to partners in this site
  # When site has tags: only events from tagged partners (no address fallback)
  # When site has no tags: events from site partners OR events with address in site neighbourhoods
  def events_for_site
    partners_scope = PartnersQuery.new(site: @site).call.reorder(nil)

    if @site.tags.any?
      events_for_tagged_site(partners_scope)
    else
      events_for_untagged_site(partners_scope)
    end
  end

  # For sites without tags: use subquery instead of materializing partners
  def events_for_untagged_site(partners_scope)
    site_neighbourhood_ids = @site.owned_neighbourhood_ids
    partner_subquery = partners_scope.select(:id)

    base = Event.left_joins(:address)
    base.where(organiser_id: partner_subquery)
        .or(base.where(addresses: { neighbourhood_id: site_neighbourhood_ids }))
  end

  # For sites with tags: must load partners for legacy name/postcode address matching
  def events_for_tagged_site(partners_scope)
    partner_records = partners_scope.includes(:address).load
    partner_names = partner_records.map { |p| p.name.downcase }
    partner_postcodes = partner_records.filter_map(&:address).map { |a| a.postcode.downcase }

    Event
      .left_joins(:address)
      .where(
        'organiser_id IN (:partner_ids) OR ' \
        '(lower(addresses.street_address) IN (:partner_names) AND ' \
        'lower(addresses.postcode) IN (:partner_postcodes))',
        partner_ids: partner_records.map(&:id),
        partner_names: partner_names,
        partner_postcodes: partner_postcodes
      )
  end

  # ===================
  # Filtering
  # ===================

  def build_filtered_scope(organiser:, place:, organiser_or_place:, neighbourhood_id:, repeating:)
    events = base_scope
    events = events.by_organiser(organiser) if organiser
    events = events.in_place(place) if place
    events = events.by_organiser_or_place(organiser_or_place) if organiser_or_place
    events = filter_by_neighbourhood(events, neighbourhood_id) if neighbourhood_id.present?
    apply_repeating_filter(events, repeating)
  end

  # Filter by physical location of event (event address, or partner address if no event address)
  # When a parent neighbourhood is selected (e.g. a district), includes all descendants
  def filter_by_neighbourhood(events, neighbourhood_id)
    neighbourhood = Neighbourhood.find_by(id: neighbourhood_id)
    return events.none unless neighbourhood

    matching_ids = neighbourhood.subtree_ids
    events
      .left_joins(:address, organiser: :address)
      .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IN (?)', matching_ids)
      .distinct
  end

  def apply_repeating_filter(events, repeating)
    case repeating
    when 'off' then events.one_off_events_only
    when 'last' then events.one_off_events_first
    else events
    end
  end

  # ===================
  # Period Selection
  # ===================

  def apply_period(events, period)
    case period
    when 'future' then apply_future_period(events)
    when 'upcoming' then events.future(@day).limit(UPCOMING_LIMIT)
    when 'month' then events.for_month(@day)
    when 'week' then events.find_next_7_days(@day)
    else events.find_by_day(@day)
    end
  end

  def apply_future_period(events)
    future_events = events.future(@day)
    @truncated = future_events.count > FUTURE_LIMIT
    future_events.limit(FUTURE_LIMIT)
  end

  # ===================
  # Sorting & Grouping
  # ===================

  def group_and_sort(events, sort)
    if sort == 'summary'
      { @day => events.sort_by_summary }
    else
      events.distinct.sort_by_time.group_by_day(&:dtstart)
    end
  end

  # Compute subtree event counts using in-memory ancestry data (no extra queries).
  # Builds a parent→children map, then propagates leaf counts upward.
  def subtree_counts_from_ancestry(descendants, raw_counts)
    ids = descendants.to_set(&:id)
    children_map = Hash.new { |h, k| h[k] = [] }
    roots = []

    descendants.each do |n|
      if n.parent_id && ids.include?(n.parent_id)
        children_map[n.parent_id] << n.id
      else
        roots << n.id
      end
    end

    counts = {}
    # Post-order traversal: compute children first, then sum into parent
    compute = lambda do |id|
      own = raw_counts[id] || 0
      child_sum = children_map[id].sum { |cid| compute.call(cid) }
      counts[id] = own + child_sum
    end
    roots.each { |id| compute.call(id) }
    counts
  end
end
