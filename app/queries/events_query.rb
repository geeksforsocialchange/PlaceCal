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

  # Upcoming-event counts keyed by partner id, counting events a partner either
  # hosts (place) or organises. Used to badge partner rows/cards in the directory.
  #
  # @param partner_ids [Array<Integer>] partners to count events for
  # @return [Hash{Integer=>Integer}] partner id => upcoming event count
  def self.upcoming_counts_by_partner(partner_ids)
    return {} if partner_ids.blank?

    future = Event.future(Time.current)
    future.where(place_id: partner_ids)
          .or(future.where(organiser_id: partner_ids))
          .group(:place_id)
          .count
  end

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
  # @param tag_id [Integer] filter to events whose organiser or place carries
  #   this tag (used by the public region filter, see #3368 D7)
  # @param limit [Integer] max number of events to return
  #
  # @return [Hash] events grouped by date { Date => [Event, ...] }
  # rubocop:disable Metrics/ParameterLists
  def call(period:, sort: 'time', repeating: 'on', organiser: nil, place: nil,
           organiser_or_place: nil, neighbourhood_id: nil, tag_id: nil, limit: nil)
    # rubocop:enable Metrics/ParameterLists
    events = build_filtered_scope(
      organiser: organiser,
      place: place,
      organiser_or_place: organiser_or_place,
      neighbourhood_id: neighbourhood_id,
      tag_id: tag_id,
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

  # Returns a flat, sorted relation suitable for pagination (no grouping)
  #
  # @param period [String] 'day', 'week', 'month', or 'future'
  # @return [ActiveRecord::Relation<Event>]
  def flat_call(period:)
    apply_period(build_filtered_scope(repeating: 'on'), period).distinct.sort_by_time
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

  # Count methods for determining default period.
  #
  # Each takes the same optional tag_id as #call, so a region-filtered listing
  # picks its period, its monthly toggle and its next-event link from the
  # region's own events rather than the whole site's (#3368 D7).
  #
  # @param tag_id [Integer, nil] restrict to events whose organiser or place
  #   carries this tag
  def future_count(tag_id: nil)
    filter_by_tag(base_scope, tag_id).future(@day).count
  end

  def next_7_days_count(tag_id: nil)
    filter_by_tag(base_scope, tag_id).find_next_7_days(@day).count
  end

  def monthly_count(tag_id: nil)
    filter_by_tag(base_scope, tag_id).for_month(@day).count
  end

  def show_monthly?(tag_id: nil)
    monthly_count(tag_id: tag_id) <= FUTURE_LIMIT
  end

  # The soonest event on or after `day`. `future` only filters, so without an
  # explicit order this took whatever row the database returned first.
  def next_event_after(day, tag_id: nil)
    filter_by_tag(base_scope, tag_id).future(day).reorder(dtstart: :asc).first
  end

  # Returns neighbourhoods that have events, with counts for the given period
  # Used for filter dropdowns
  #
  # Shows all descendant neighbourhoods of the site's configured neighbourhoods,
  # at every level. Each neighbourhood's count includes events in its subtree.
  #
  # @param period [String] 'day', 'week', or 'future'
  # @param tag_id [Integer] optionally restrict to a tag, so the counts agree
  #   with a region-filtered listing
  # @return [Array<Hash>] array of { neighbourhood: Neighbourhood, count: Integer }
  def neighbourhoods_with_counts(period: 'future', tag_id: nil)
    return [] unless @site

    site_root_ids = @site.neighbourhoods.pluck(:id)
    return [] if site_root_ids.empty?

    events = apply_period(filter_by_tag(base_scope, tag_id), period)

    # Events counted against the neighbourhood they happen in (single query)
    raw_counts = events
                 .left_joins(:address, organiser: :address)
                 .where('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id) IS NOT NULL')
                 .group('COALESCE(addresses.neighbourhood_id, addresses_partners.neighbourhood_id)')
                 .distinct
                 .count

    dropdown_neighbourhoods(raw_counts, site_root_ids)
  end

  # Whether the given event appears on this site — same rules as the event
  # listing. Always true for the directory (site: nil).
  #
  # @param event [Event]
  # @return [Boolean]
  def include?(event)
    base_scope.exists?(event.id)
  end

  private

  # ===================
  # Base Scope
  # ===================

  def base_scope
    @base_scope ||= if @site.nil?
                      Event.includes(:place, :organiser)
                    else
                      events_for_site.includes(:place, :organiser)
                    end
  end

  # Inline of Event.for_site: the events that belong on this site. Both site
  # shapes take events organised by, or hosted at, one of the site's partners;
  # a neighbourhood site also takes any event whose address is in its area,
  # and a tagged site adds the legacy venue match. The hosted-at rule reaches
  # an event a site partner puts on somewhere else, which is how the partner
  # page and the tag filter already count it.
  def events_for_site
    if @site.tags.any?
      events_for_tagged_site(site_partner_ids)
    else
      events_for_untagged_site(site_partner_ids)
    end
  end

  # The site's partner ids, fetched once per query object and handed to
  # Postgres as a literal list. As a subquery the planner hashed the set and
  # scanned every future event for each count: 600ms against 12ms on
  # production data, four counts per events page. Ids only, never rows.
  def site_partner_ids
    @site_partner_ids ||= PartnersQuery.new(site: @site).call.reorder(nil).except(:includes).pluck(:id)
  end

  # For sites without tags: partner events plus anything at a site address.
  def events_for_untagged_site(partner_ids)
    site_neighbourhood_ids = @site.owned_neighbourhood_ids

    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(addresses: { neighbourhood_id: site_neighbourhood_ids }))
  end

  # For sites with tags: events organised by, or hosted at, a partner in the
  # site scope, plus the legacy venue match.
  def events_for_tagged_site(partner_ids)
    return Event.none if partner_ids.empty?

    base = Event.left_joins(:address)
    base.where(organiser_id: partner_ids)
        .or(base.where(place_id: partner_ids))
        .or(base.where(legacy_venue_match_sql(partner_ids)))
  end

  # Legacy venue matching, from 2024 (commit 5b90f19), for events whose place
  # was never set: an event counts as happening at a partner when its address
  # street line is the partner's name and the postcodes agree. Ids are cast
  # to integers again before interpolation.
  def legacy_venue_match_sql(partner_ids)
    <<~SQL.squish
      EXISTS (SELECT 1 FROM partners venue_partners
        INNER JOIN addresses venue_addresses ON venue_addresses.id = venue_partners.address_id
        WHERE venue_partners.id IN (#{partner_ids.map(&:to_i).join(',')})
        AND lower(venue_partners.name) = lower(addresses.street_address) AND lower(venue_addresses.postcode) = lower(addresses.postcode))
    SQL
  end

  # ===================
  # Filtering
  # ===================

  # rubocop:disable Metrics/ParameterLists
  def build_filtered_scope(repeating:, organiser: nil, place: nil, organiser_or_place: nil,
                           neighbourhood_id: nil, tag_id: nil)
    # rubocop:enable Metrics/ParameterLists
    events = base_scope
    events = filter_by_tag(events, tag_id)
    events = events.by_organiser(organiser) if organiser
    events = events.in_place(place) if place
    events = events.by_organiser_or_place(organiser_or_place) if organiser_or_place
    events = filter_by_neighbourhood(events, neighbourhood_id) if neighbourhood_id.present?
    apply_repeating_filter(events, repeating)
  end

  # Restrict to events whose organiser or place carries the tag. Mirrors
  # PartnersQuery#filter_by_tag: the region filter is a partnership-tag filter,
  # and an event belongs to a region when the partner behind it does.
  # A blank tag_id means no region is selected, so the scope passes through.
  def filter_by_tag(events, tag_id)
    return events if tag_id.blank?

    partner_ids = PartnerTag.where(tag_id: tag_id).pluck(:partner_id)
    events.where(organiser_id: partner_ids).or(events.where(place_id: partner_ids))
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

  # The neighbourhood dropdown: every neighbourhood with events in its subtree,
  # each carrying that subtree's event count, sorted by name.
  #
  # Only the neighbourhoods that have events and their ancestors can carry a
  # non-zero count, so we load just those rather than every descendant of the
  # site. A country-anchored site has ~13,000 descendants; loading them all to
  # fill a handful-long dropdown cost ~2s a request. Entries are kept to strict
  # descendants of the site's own neighbourhoods, so the anchor nodes are
  # excluded, matching the previous descendants-only behaviour.
  #
  # @param raw_counts [Hash{Integer=>Integer}] event count per neighbourhood id
  # @param site_root_ids [Array<Integer>] the site's own neighbourhood ids
  # @return [Array<Hash>] { neighbourhood:, count: } sorted by name
  def dropdown_neighbourhoods(raw_counts, site_root_ids)
    return [] if raw_counts.empty?

    event_hoods = Neighbourhood.where(id: raw_counts.keys).to_a
    candidate_ids = (raw_counts.keys + event_hoods.flat_map(&:ancestor_ids)).uniq

    Neighbourhood.where(id: candidate_ids).order(:name).filter_map do |node|
      next unless (node.ancestor_ids & site_root_ids).any?

      # An event counts towards a node when the node is an ancestor-or-self of
      # the neighbourhood the event is in, i.e. the event sits in its subtree.
      count = event_hoods.sum { |h| h.path_ids.include?(node.id) ? raw_counts[h.id] : 0 }
      { neighbourhood: node, count: count } if count.positive?
    end
  end
end
